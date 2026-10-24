#!/bin/bash
# Copy a devcontainer configuration from the shelterbelt/docker stack images into this project.
#
# Two modes:
#   interactive  ./.setup/add-devcontainer.sh                 # pick stack, then variant
#   cli          ./.setup/add-devcontainer.sh rails --full    # non-interactive
#
# Configs are fetched from the source repo at run time (never vendored here), flattened into
# ./.devcontainer/, repointed at the published GHCR images, and given project-scoped volume
# names so two projects on the same Docker host never share a database.

set -euo pipefail

SOURCE_REPO="${DEVCONTAINER_SOURCE_REPO:-shelterbelt/docker}"
SOURCE_REF="${DEVCONTAINER_SOURCE_REF:-main}"
GHCR_OWNER="${DEVCONTAINER_GHCR_OWNER:-shelterbelt}"
IMAGE_TAG="${DEVCONTAINER_IMAGE_TAG:-latest}"

DEST_ROOT="$PWD"
VARIANT=""
STACK_ARG=""
PROJECT_NAME=""
DO_LIST=0
DO_FORCE=0
DO_DRY_RUN=0
DO_FONTS=0
DO_GHCR=1
DO_NAMESPACE=1

WORK_DIR=""
cleanup() { [ -n "$WORK_DIR" ] && rm -rf "$WORK_DIR"; }
trap cleanup EXIT

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: add-devcontainer.sh [options] [<stack>]

Copies a devcontainer configuration from the shelterbelt/docker stack images into
./.devcontainer/. Run with no <stack> for an interactive menu.

Arguments:
  <stack>                Stack to install. Accepts the manifest id (node-t3), the
                         config name (t3), or an explicit variant (rails-full).

Options:
  -f, --full             Install the full (batteries-included) variant.
  -r, --ready            Install the ready variant. [default]
  -l, --list             List available stacks and exit.
  -d, --dest <dir>       Destination project root. [default: current directory]
  -n, --dry-run          Show what would be written without writing it.
      --force            Overwrite an existing .devcontainer/ config.
      --name <name>      Prefix for namespaced volumes. [default: basename of --dest]
      --owner <owner>    GHCR owner. [default: shelterbelt]
      --tag <tag>        Image tag to pull. [default: latest]
      --repo <owner/rep> Source repository. [default: shelterbelt/docker]
      --ref <ref>        Source branch, tag, or SHA. [default: main]
      --with-fonts       Also copy .devcontainer/fonts/ (MesloLGS NF, used by the
                         terminal.integrated.fontFamily setting).
      --keep-local-image Leave `image: <name>:local` alone instead of pointing at GHCR.
      --no-namespace     Keep the upstream `dev-*` volume names instead of prefixing them.
  -h, --help             Show this help.

Environment overrides: DEVCONTAINER_SOURCE_REPO, DEVCONTAINER_SOURCE_REF,
DEVCONTAINER_GHCR_OWNER, DEVCONTAINER_IMAGE_TAG.

Requires: gh (authenticated — the source repo is private), jq, tar.
EOF
}

# ---------------------------------------------------------------- argument parsing

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--full)          VARIANT="full" ;;
    -r|--ready)         VARIANT="ready" ;;
    -l|--list)          DO_LIST=1 ;;
    -n|--dry-run)       DO_DRY_RUN=1 ;;
    --force)            DO_FORCE=1 ;;
    --with-fonts)       DO_FONTS=1 ;;
    --keep-local-image) DO_GHCR=0 ;;
    --no-namespace)     DO_NAMESPACE=0 ;;
    -d|--dest)          DEST_ROOT="${2:?--dest requires a directory}"; shift ;;
    --name)             PROJECT_NAME="${2:?--name requires a value}"; shift ;;
    --owner)            GHCR_OWNER="${2:?--owner requires a value}"; shift ;;
    --tag)              IMAGE_TAG="${2:?--tag requires a value}"; shift ;;
    --repo)             SOURCE_REPO="${2:?--repo requires owner/repo}"; shift ;;
    --ref)              SOURCE_REF="${2:?--ref requires a git ref}"; shift ;;
    -h|--help)          usage; exit 0 ;;
    -*)                 die "unknown option: $1 (try --help)" ;;
    *)
      [ -n "$STACK_ARG" ] && die "unexpected extra argument: $1"
      STACK_ARG="$1"
      ;;
  esac
  shift
done

for tool in gh jq tar; do
  command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required but not installed."
done

[ -d "$DEST_ROOT" ] || die "destination is not a directory: $DEST_ROOT"
DEST_ROOT="$(cd "$DEST_ROOT" && pwd)"

# ---------------------------------------------------------------- fetch the source

fetch_source() {
  WORK_DIR="$(mktemp -d)"
  info "Fetching ${SOURCE_REPO}@${SOURCE_REF}..."
  if ! gh api "repos/${SOURCE_REPO}/tarball/${SOURCE_REF}" > "${WORK_DIR}/source.tar.gz" 2>"${WORK_DIR}/fetch.err"; then
    info "$(cat "${WORK_DIR}/fetch.err")"
    die "could not fetch ${SOURCE_REPO}@${SOURCE_REF}. The repo is private — check 'gh auth status'."
  fi
  mkdir -p "${WORK_DIR}/src"
  tar -xzf "${WORK_DIR}/source.tar.gz" -C "${WORK_DIR}/src" --strip-components=1
  SRC="${WORK_DIR}/src"
  [ -f "${SRC}/shared/stacks.json" ] || die "no shared/stacks.json in ${SOURCE_REPO}@${SOURCE_REF}"
  [ -d "${SRC}/.devcontainer" ] || die "no .devcontainer/ in ${SOURCE_REPO}@${SOURCE_REF}"
}

# Strip JSONC comments so jq can read a devcontainer.json.
strip_jsonc() {
  sed -e 's|^[[:space:]]*//.*$||' -e 's|[[:space:]]//[[:space:]].*$||' "$1"
}

# Print the `image:` value of a service in a compose file. Ignores comments and other services.
compose_image_for_service() {
  awk -v svc="$2" '
    $0 ~ "^  " svc ":[[:space:]]*$" { in_svc = 1; next }
    /^  [A-Za-z0-9_.-]+:[[:space:]]*$/ { in_svc = 0 }
    in_svc && $1 == "image:" { print $2; exit }
  ' "$1"
}

# Print the named volumes declared in a compose file's top-level `volumes:` block.
compose_volume_names() {
  awk '
    /^volumes:[[:space:]]*$/ { in_vol = 1; next }
    /^[A-Za-z]/ { in_vol = 0 }
    in_vol && /^  [A-Za-z0-9_.-]+:[[:space:]]*$/ { sub(/:.*$/, "", $1); print $1 }
  ' "$1"
}

# ---------------------------------------------------------------- build the catalog
#
# stacks.json is the single source of truth for stack identity, but the config directory
# names don't always match the ids (`node-t3` lives at .devcontainer/t3/). Rather than
# hardcoding that alias, map each config directory to the image its service resolves to,
# then look the images up in the manifest. Bash 3.2 has no associative arrays, so these
# are parallel indexed arrays.

IDS=(); READY_IMAGES=(); FULL_IMAGES=()
READY_DIRS=(); FULL_DIRS=()
SCAN_IMAGES=(); SCAN_DIRS=()

index_of_image() {
  local needle="$1" i=0
  while [ $i -lt ${#SCAN_IMAGES[@]} ]; do
    [ "${SCAN_IMAGES[$i]}" = "$needle" ] && { printf '%s' "${SCAN_DIRS[$i]}"; return 0; }
    i=$((i + 1))
  done
  return 1
}

scan_configs() {
  local cfg dir service compose image
  for cfg in "${SRC}"/.devcontainer/*/devcontainer.json; do
    [ -f "$cfg" ] || continue
    dir="$(basename "$(dirname "$cfg")")"
    service="$(strip_jsonc "$cfg" | jq -r '.service // empty')"
    compose="$(strip_jsonc "$cfg" | jq -r '.dockerComposeFile | if type == "array" then .[0] else . end // empty')"
    [ -n "$service" ] && [ -n "$compose" ] || continue
    compose="${SRC}/.devcontainer/${dir}/${compose}"
    [ -f "$compose" ] || continue
    image="$(compose_image_for_service "$compose" "$service")"
    image="${image%%:*}"
    [ -n "$image" ] || continue
    SCAN_IMAGES+=("$image")
    SCAN_DIRS+=("$dir")
  done
}

load_manifest() {
  local line id ready full
  while IFS=$'\t' read -r id ready full; do
    IDS+=("$id")
    READY_IMAGES+=("$ready")
    FULL_IMAGES+=("$full")
    READY_DIRS+=("$(index_of_image "$ready" || true)")
    if [ -n "$full" ]; then
      FULL_DIRS+=("$(index_of_image "$full" || true)")
    else
      FULL_DIRS+=("")
    fi
  done < <(jq -r '
    .stacks[]
    | [ .id,
        (.ready.image // ""),
        (if (.full.enabled // false) then (.full.image // "") else "" end)
      ] | @tsv' "${SRC}/shared/stacks.json")
}

list_stacks() {
  local i=0
  printf '\nAvailable stacks (%s@%s):\n\n' "$SOURCE_REPO" "$SOURCE_REF"
  printf '  %-12s  %-10s  %s\n' "STACK" "VARIANTS" "IMAGES"
  while [ $i -lt ${#IDS[@]} ]; do
    if [ -n "${FULL_DIRS[$i]}" ]; then
      printf '  %-12s  %-10s  %s, %s\n' "${IDS[$i]}" "ready,full" "${READY_IMAGES[$i]}" "${FULL_IMAGES[$i]}"
    else
      printf '  %-12s  %-10s  %s\n' "${IDS[$i]}" "ready" "${READY_IMAGES[$i]}"
    fi
    i=$((i + 1))
  done
  printf '\n'
}

# ---------------------------------------------------------------- selection

SELECTED=-1

resolve_stack_arg() {
  local want="$1" i=0

  # An explicit `<stack>-full` argument selects the variant too.
  if [ -z "$VARIANT" ] && [ "${want%-full}" != "$want" ]; then
    local bare="${want%-full}"
    i=0
    while [ $i -lt ${#IDS[@]} ]; do
      if [ "$bare" = "${IDS[$i]}" ] || [ "$bare" = "${READY_DIRS[$i]}" ]; then
        SELECTED=$i; VARIANT="full"; return 0
      fi
      i=$((i + 1))
    done
  fi

  i=0
  while [ $i -lt ${#IDS[@]} ]; do
    if [ "$want" = "${IDS[$i]}" ] || [ "$want" = "${READY_DIRS[$i]}" ]; then
      SELECTED=$i; return 0
    fi
    if [ -n "${FULL_DIRS[$i]}" ] && [ "$want" = "${FULL_DIRS[$i]}" ]; then
      SELECTED=$i; [ -z "$VARIANT" ] && VARIANT="full"; return 0
    fi
    i=$((i + 1))
  done

  die "unknown stack: $want (run with --list to see the available stacks)"
}

prompt_stack() {
  local i=0 choice
  printf '\nSelect a stack:\n\n' >&2
  while [ $i -lt ${#IDS[@]} ]; do
    printf '  %2d) %s\n' "$((i + 1))" "${IDS[$i]}" >&2
    i=$((i + 1))
  done
  printf '\n' >&2
  while :; do
    printf 'Stack [1-%d]: ' "${#IDS[@]}" >&2
    read -r choice || die "no selection made"
    case "$choice" in
      ''|*[!0-9]*) ;;
      *) if [ "$choice" -ge 1 ] && [ "$choice" -le "${#IDS[@]}" ]; then
           SELECTED=$((choice - 1)); return 0
         fi ;;
    esac
    printf 'Enter a number between 1 and %d.\n' "${#IDS[@]}" >&2
  done
}

prompt_variant() {
  local choice
  if [ -z "${FULL_DIRS[$SELECTED]}" ]; then
    VARIANT="ready"
    return 0
  fi
  printf '\nSelect a variant for %s:\n\n' "${IDS[$SELECTED]}" >&2
  printf '   1) ready  — the lean stack image\n' >&2
  printf '   2) full   — batteries included (extra global CLIs and tooling)\n\n' >&2
  while :; do
    printf 'Variant [1-2]: ' >&2
    read -r choice || die "no selection made"
    case "$choice" in
      1) VARIANT="ready"; return 0 ;;
      2) VARIANT="full";  return 0 ;;
      *) printf 'Enter 1 or 2.\n' >&2 ;;
    esac
  done
}

# ---------------------------------------------------------------- transforms

# sed in place, portably across BSD and GNU sed.
rewrite() {
  local expr="$1" file="$2"
  sed "$expr" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

sanitize_name() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9_-]/-/g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//'
}

# ---------------------------------------------------------------- main

fetch_source
scan_configs
load_manifest

[ ${#IDS[@]} -gt 0 ] || die "no stacks found in the manifest"

if [ "$DO_LIST" -eq 1 ]; then
  list_stacks
  exit 0
fi

if [ -n "$STACK_ARG" ]; then
  resolve_stack_arg "$STACK_ARG"
else
  [ -t 0 ] || die "no stack given and stdin is not a terminal (pass a stack, or use --list)"
  prompt_stack
fi

if [ -z "$VARIANT" ]; then
  if [ -n "$STACK_ARG" ]; then
    VARIANT="ready"
  else
    prompt_variant
  fi
fi

if [ "$VARIANT" = "full" ] && [ -z "${FULL_DIRS[$SELECTED]}" ]; then
  die "${IDS[$SELECTED]} has no full variant (it is a ready-only stack)"
fi

STACK_ID="${IDS[$SELECTED]}"
if [ "$VARIANT" = "full" ]; then
  CONFIG_DIR="${FULL_DIRS[$SELECTED]}"
  IMAGE_NAME="${FULL_IMAGES[$SELECTED]}"
else
  CONFIG_DIR="${READY_DIRS[$SELECTED]}"
  IMAGE_NAME="${READY_IMAGES[$SELECTED]}"
fi
[ -n "$CONFIG_DIR" ] || die "no devcontainer config found for ${STACK_ID} (${VARIANT})"

SRC_CONFIG="${SRC}/.devcontainer/${CONFIG_DIR}/devcontainer.json"
SRC_COMPOSE_REL="$(strip_jsonc "$SRC_CONFIG" | jq -r '.dockerComposeFile | if type == "array" then .[0] else . end')"
SRC_COMPOSE="${SRC}/.devcontainer/${CONFIG_DIR}/${SRC_COMPOSE_REL}"
[ -f "$SRC_COMPOSE" ] || die "compose file missing for ${STACK_ID}: ${SRC_COMPOSE_REL}"

[ -n "$PROJECT_NAME" ] || PROJECT_NAME="$(basename "$DEST_ROOT")"
PROJECT_NAME="$(sanitize_name "$PROJECT_NAME")"
[ -n "$PROJECT_NAME" ] || die "could not derive a usable project name; pass --name"

DEST_DIR="${DEST_ROOT}/.devcontainer"
DEST_CONFIG="${DEST_DIR}/devcontainer.json"
DEST_COMPOSE="${DEST_DIR}/docker-compose.yml"

if [ "$DO_FORCE" -eq 0 ]; then
  for existing in "$DEST_CONFIG" "$DEST_COMPOSE"; do
    [ -e "$existing" ] && die "${existing#"$DEST_ROOT"/} already exists (pass --force to overwrite)"
  done
fi

SOURCE_SHA="$(gh api "repos/${SOURCE_REPO}/commits/${SOURCE_REF}" --jq '.sha' 2>/dev/null | cut -c1-7 || printf 'unknown')"
STAMP="$(date -u '+%Y-%m-%d')"

STAGE="${WORK_DIR}/stage"
mkdir -p "$STAGE"
cp "$SRC_CONFIG" "${STAGE}/devcontainer.json"
cp "$SRC_COMPOSE" "${STAGE}/docker-compose.yml"

# --- devcontainer.json -------------------------------------------------------
# The config is flattened to .devcontainer/, so a `-full` variant's pointer at its sibling
# ready directory's compose (../<stack>/docker-compose.yml) has to become a local reference.
rewrite 's|^\([[:space:]]*\)"dockerComposeFile":.*$|\1"dockerComposeFile": ["docker-compose.yml"],|' \
  "${STAGE}/devcontainer.json"

# --- docker-compose.yml ------------------------------------------------------
# Flattening moves the compose file up one level, so the workspace bind mount (and the
# commented bind-mount alternatives) must lose a path segment or /workspace resolves above
# the project root.
rewrite 's|\.\./\.\.|..|g' "${STAGE}/docker-compose.yml"

if [ "$DO_GHCR" -eq 1 ]; then
  rewrite "s|^\([[:space:]]*\)image:[[:space:]]*\([A-Za-z0-9_.-]*\):local[[:space:]]*\$|\1image: ghcr.io/${GHCR_OWNER}/\2:${IMAGE_TAG}|" \
    "${STAGE}/docker-compose.yml"
  # The upstream comments carry a commented-out GHCR override with a literal <owner>
  # placeholder and a hardcoded :latest. Bring both in line with what was actually written
  # so the comment can't contradict the live image reference.
  rewrite "s|ghcr.io/<owner>/\([A-Za-z0-9_.-]*\):latest|ghcr.io/${GHCR_OWNER}/\1:${IMAGE_TAG}|g" \
    "${STAGE}/docker-compose.yml"
  # The same comment ends with a "Replace <owner>:" instruction that no longer applies once the
  # substitution above has been made. Drop the clause rather than leave it addressing nobody.
  rewrite 's|[[:space:]]*Replace <owner>:$||' "${STAGE}/docker-compose.yml"
  rewrite "s|<owner>|${GHCR_OWNER}|g" "${STAGE}/docker-compose.yml"
fi

RENAMED_VOLUMES=""
if [ "$DO_NAMESPACE" -eq 1 ]; then
  while read -r vol; do
    [ -n "$vol" ] || continue
    newvol="${PROJECT_NAME}-${vol#dev-}"
    # Anchor on the line shape so only declarations and mounts are touched, never image
    # references or the surrounding prose.
    rewrite "s|^\([[:space:]]*- \)${vol}:|\1${newvol}:|" "${STAGE}/docker-compose.yml"
    rewrite "s|^\([[:space:]]*\)${vol}:|\1${newvol}:|" "${STAGE}/docker-compose.yml"
    RENAMED_VOLUMES="${RENAMED_VOLUMES}${vol} -> ${newvol}"$'\n'
  done < <(compose_volume_names "$SRC_COMPOSE")
fi

# --- provenance headers ------------------------------------------------------
PROVENANCE=$(cat <<EOF
// Copied from ${SOURCE_REPO}@${SOURCE_SHA} (.devcontainer/${CONFIG_DIR}/) on ${STAMP}
// by .setup/add-devcontainer.sh. Stack: ${STACK_ID} (${VARIANT}).
// Flattened to .devcontainer/, so dockerComposeFile is a local reference and the compose
// workspace mount is one level shallower than upstream. Comments below still describe the
// upstream two-level layout. Re-run the script to refresh.
EOF
)
printf '%s\n' "$PROVENANCE" > "${STAGE}/devcontainer.json.out"
cat "${STAGE}/devcontainer.json" >> "${STAGE}/devcontainer.json.out"
mv "${STAGE}/devcontainer.json.out" "${STAGE}/devcontainer.json"

printf '%s\n' "$PROVENANCE" | sed 's|^//|#|' > "${STAGE}/docker-compose.yml.out"
cat "${STAGE}/docker-compose.yml" >> "${STAGE}/docker-compose.yml.out"
mv "${STAGE}/docker-compose.yml.out" "${STAGE}/docker-compose.yml"

# --- write -------------------------------------------------------------------

if [ "$DO_DRY_RUN" -eq 1 ]; then
  printf '\n--- dry run: nothing written ---\n\n'
  printf 'stack          %s (%s)\n' "$STACK_ID" "$VARIANT"
  printf 'source         %s@%s  .devcontainer/%s/\n' "$SOURCE_REPO" "$SOURCE_SHA" "$CONFIG_DIR"
  printf 'would write    %s\n' "${DEST_CONFIG#"$DEST_ROOT"/}"
  printf '               %s\n' "${DEST_COMPOSE#"$DEST_ROOT"/}"
  [ "$DO_FONTS" -eq 1 ] && printf '               %s\n' ".devcontainer/fonts/"
  if [ "$DO_GHCR" -eq 1 ]; then
    printf 'image          ghcr.io/%s/%s:%s\n' "$GHCR_OWNER" "$IMAGE_NAME" "$IMAGE_TAG"
  else
    printf 'image          %s:local (unchanged)\n' "$IMAGE_NAME"
  fi
  if [ -n "$RENAMED_VOLUMES" ]; then
    printf 'volumes\n'
    printf '%s' "$RENAMED_VOLUMES" | sed 's|^|               |'
  fi
  printf '\n--- .devcontainer/docker-compose.yml (services and volumes) ---\n'
  grep -nE '^\s*image:|^\s+- |^volumes:|^services:|^  [a-z0-9_-]+:' "${STAGE}/docker-compose.yml" | grep -v '^\s*[0-9]*:\s*#'
  printf '\n'
  exit 0
fi

mkdir -p "$DEST_DIR"
cp "${STAGE}/devcontainer.json" "$DEST_CONFIG"
cp "${STAGE}/docker-compose.yml" "$DEST_COMPOSE"

if [ "$DO_FONTS" -eq 1 ]; then
  if [ -d "${SRC}/.devcontainer/fonts" ]; then
    rm -rf "${DEST_DIR}/fonts"
    cp -R "${SRC}/.devcontainer/fonts" "${DEST_DIR}/fonts"
  else
    info "warning: no .devcontainer/fonts/ in the source repo; skipped"
  fi
fi

# ---------------------------------------------------------------- summary

cat <<EOF

Installed ${STACK_ID} (${VARIANT}) into .devcontainer/

  source     ${SOURCE_REPO}@${SOURCE_SHA}  .devcontainer/${CONFIG_DIR}/
  config     .devcontainer/devcontainer.json
  compose    .devcontainer/docker-compose.yml
EOF

if [ "$DO_GHCR" -eq 1 ]; then
  printf '  image      ghcr.io/%s/%s:%s\n' "$GHCR_OWNER" "$IMAGE_NAME" "$IMAGE_TAG"
else
  printf '  image      %s:local (build it in the source repo first)\n' "$IMAGE_NAME"
fi

if [ -n "$RENAMED_VOLUMES" ]; then
  printf '  volumes    namespaced to "%s-"\n' "$PROJECT_NAME"
fi
[ "$DO_FONTS" -eq 1 ] && printf '  fonts      .devcontainer/fonts/ (install MesloLGS NF on the host)\n'

cat <<'EOF'

Next steps:
EOF

if [ "$DO_GHCR" -eq 1 ]; then
  printf '  1. The GHCR packages are private — authenticate Docker once:\n'
  printf '       echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin\n'
  printf '     (or: gh auth token | docker login ghcr.io -u "$(gh api user --jq .login)" --password-stdin)\n'
  printf '  2. Reopen in Container from your editor.\n'
else
  printf '  1. Build the image in the source repo, then reopen in Container.\n'
fi

if [ "$DO_FONTS" -eq 0 ]; then
  printf '%s\n' '' \
    'Note: the config sets terminal.integrated.fontFamily to "MesloLGS NF". Re-run with' \
    '--with-fonts to copy the font files, or install them on your host separately.'
fi
printf '\n'

---
description: Install a devcontainer configuration for a tech stack — copies it from the shelterbelt/docker stack images into .devcontainer/
---

Install a devcontainer configuration into this project using `.setup/add-devcontainer.sh`.

The script fetches configs from `shelterbelt/docker` at run time, flattens the chosen one into
`./.devcontainer/`, repoints it at the published GHCR image, and namespaces the Docker volumes
to this project so two projects never share a database.

## Steps

1. If the user named a stack, run it directly in CLI mode:

   ```bash
   ./.setup/add-devcontainer.sh <stack> [--full]
   ```

2. If the user did **not** name a stack, do not guess. List what's available and ask which one
   they want, and whether they want the `ready` or `full` variant:

   ```bash
   ./.setup/add-devcontainer.sh --list
   ```

   Never launch the script's own interactive menu — it needs a real terminal. Resolve the
   choice in conversation, then run CLI mode.

3. Before writing, preview the result if the change is non-obvious or `.devcontainer/` already
   has content:

   ```bash
   ./.setup/add-devcontainer.sh <stack> [--full] --dry-run
   ```

4. Report what landed: the stack and variant, the GHCR image, and the volume prefix.

## Variants

- `ready` — the lean stack image. The default.
- `full` — batteries included: extra global CLIs and tooling baked in.

`opencode` and `ollama` are ready-only; asking for `--full` on those is an error.

## Notes

- Requires `gh` (authenticated), `jq`, and `tar`. The source repo is private.
- The GHCR packages are private too. After install, the user must `docker login ghcr.io` once
  before "Reopen in Container" will work. Surface this — it is the most common failure.
- `--force` is required to overwrite an existing `.devcontainer/devcontainer.json`. Do not pass
  it without checking with the user first.
- Useful flags: `--owner`, `--tag`, `--ref`, `--name`, `--with-fonts`, `--keep-local-image`,
  `--no-namespace`, `--dest`. Run with `--help` for the full list.

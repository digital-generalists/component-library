# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Copilot, Antigravity, etc.) when working with code in this repository.

## Repository Overview

Re-usable components for multiple languages, platforms, and frameworks, by Digital Generalists.

The repository is intended to house components for many platforms. The initial release contains a single iOS package, `DGCoreUI` (`apple/ios/core-ui/`): an Objective-C/UIKit framework providing the Tool Shelf (`DGToolShelfViewController`) and Presentation Cards (`DGCardPresentationViewController`) components, plus a SwiftUI `ReferenceImplementation` app that demonstrates them. See `README.md` for component details, supported versions, and integration steps.

### Repository Conventions

- Components are organized by platform, then package: `apple/ios/core-ui/`. New platforms and frameworks go in sibling directories at the matching level (e.g. `apple/macos/`, `android/`, `web/react/`).
- Each package is self-contained — its own project files, build configuration, and reference implementation. A package does not depend on files outside its directory.
- Every package ships a reference implementation that demonstrates each of its components in a running application. It is the primary way component changes are verified.
- Every new component is added to the Components table in `README.md`, with its prerequisites, supported versions, and build steps.
- `.agents/` holds the AI agent skills, personas, commands, and references; `.claude/`, `.cursor/`, and `.opencode/` mirror it for each tool.

#### DGCoreUI (iOS)

- Framework target `DGCoreUI` supports iOS 17.0+; the `ReferenceImplementation` app targets iOS 27.0+. iPhone and iPad; no Mac Catalyst. Project files are from Xcode 27.1.
- Framework source is Objective-C; the reference app is Swift/SwiftUI and wraps components with `UIViewControllerRepresentable`.
- Source is grouped by component: `DGCoreUI/Toolshelf/`, `DGCoreUI/PresentationCards/`, and shared `DGCoreUI/Notifications/`. Shared enums, notification names, and display configuration structs live in `DGComponentTypeDefinitions.h`.
- Every public header is listed in the `DGCoreUI.h` umbrella header and imported as `<DGCoreUI/...>`. Types use the `DG` prefix.
- Components own no content: the host supplies buttons (with their targets and actions), menu definitions, cards, and styling. Components lay out, style, and transition.
- Components communicate with their hosts through notifications (`DGNotificationManager`, names defined in `DGComponentTypeDefinitions.h`), e.g. `UI_SAVE_UI_STATE` and `UI_CARD_PRESENTATION_DISMISSED`.
- Swift cannot import the C display configuration structs (they hold object pointers), so every initializer taking one has a variant taking the values individually. Keep the two in sync.
- The shared `MajicComponents` scheme is stale (it references a target since renamed to `DGCoreUI`); build the framework by target, or through the `ReferenceImplementation` scheme.

### Repository Commands

- Build the DGCoreUI framework:
  `xcodebuild -project apple/ios/core-ui/DGCoreUI.xcodeproj -target DGCoreUI -configuration Debug -sdk iphonesimulator build`
- Build the reference app (and the framework it links):
  `xcodebuild -project apple/ios/core-ui/DGCoreUI.xcodeproj -scheme ReferenceImplementation -destination 'generic/platform=iOS Simulator' build`
- Run the reference app: open `apple/ios/core-ui/DGCoreUI.xcodeproj` in Xcode, select the `ReferenceImplementation` scheme and a simulator, press Cmd+R.
- There are no automated tests yet.
- List / install devcontainer configurations: `./.setup/add-devcontainer.sh --list`, `./.setup/add-devcontainer.sh <stack> [--full]`

### Repository Rules

```
references to detailed definitions of:
 - code formatting rules and style guides
 - technology-specific best practices
 - foundational rules, standards, and procedures that apply to all aspects of the repository
```

## OpenCode Integration

OpenCode uses a **skill-driven execution model** powered by the `skill` tool and this repository's `/skills` directory.

### Core Rules

- If a task matches a skill, you MUST invoke it
- Skills are located in `skills/<skill-name>/SKILL.md`
- Never implement directly if a skill applies
- Always follow the skill instructions exactly (do not partially apply them)

### Intent → Skill Mapping

The agent should automatically map user intent to skills:

- Feature / new functionality → `spec-driven-development`, then `incremental-implementation`, `test-driven-development`
- Planning / breakdown → `planning-and-task-breakdown`
- Bug / failure / unexpected behavior → `debugging-and-error-recovery`
- Code review → `code-review-and-quality`
- Refactoring / simplification → `code-simplification`
- API or interface design → `api-and-interface-design`
- UI work → `frontend-ui-engineering`

### Lifecycle Mapping (Implicit Commands)

OpenCode does not support slash commands like `/spec` or `/plan`.

Instead, the agent must internally follow this lifecycle:

- DEFINE → `spec-driven-development`
- PLAN → `planning-and-task-breakdown`
- BUILD → `incremental-implementation` + `test-driven-development`
- VERIFY → `debugging-and-error-recovery`
- REVIEW → `code-review-and-quality`
- SHIP → `shipping-and-launch`

### Execution Model

For every request:

1. Determine if any skill applies (even 1% chance)
2. Invoke the appropriate skill using the `skill` tool
3. Follow the skill workflow strictly
4. Only proceed to implementation after required steps (spec, plan, etc.) are complete

### Anti-Rationalization

The following thoughts are incorrect and must be ignored:

- "This is too small for a skill"
- "I can just quickly implement this"
- "I’ll gather context first"

Correct behavior:

- Always check for and use skills first

This ensures OpenCode behaves similarly to Claude Code with full workflow enforcement.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name
    SKILL.md              # Required: skill definition
    scripts/              # Required: executable scripts
      {script-name}.sh    # Bash scripts (preferred)
  {skill-name}.zip        # Required: packaged for distribution
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g. `web-quality`)
- **SKILL.md**: Always uppercase, always this exact filename
- **Scripts**: `kebab-case.sh` (e.g., `deploy.sh`, `fetch-logs.sh`)
- **Zip file**: Must match directory name exactly: `{skill-name}.zip`

### SKILL.md Format

```markdown
---
name: {skill-name}
description: {One sentence describing when to use this skill. Include trigger phrases like "Deploy my app", "Check logs", etc.}
---

# {Skill Title}

{Brief description of what the skill does.}

## How It Works

{Numbered list explaining the skill's workflow}

## Usage

```bash
bash /mnt/skills/user/{skill-name}/scripts/{script}.sh [args]
```

**Arguments:**
- `arg1` - Description (defaults to X)

**Examples:**
{Show 2-3 common usage patterns}

## Output

{Show example output users will see}

## Present Results to User

{Template for how Claude should format results when presenting to users}

## Troubleshooting

{Common issues and solutions, especially network/permissions errors}
```

### Best Practices for Context Efficiency

Skills are loaded on-demand — only the skill name and description are loaded at startup. The full `SKILL.md` loads into context only when the agent decides the skill is relevant. To minimize context usage:

- **Keep SKILL.md under 500 lines** — put detailed reference material in separate files
- **Write specific descriptions** — helps the agent know exactly when to activate the skill
- **Use progressive disclosure** — reference supporting files that get read only when needed
- **Prefer scripts over inline code** — script execution doesn't consume context (only output does)
- **File references work one level deep** — link directly from SKILL.md to supporting files

### Script Requirements

- Use `#!/bin/bash` shebang
- Use `set -e` for fail-fast behavior
- Write status messages to stderr: `echo "Message" >&2`
- Write machine-readable output (JSON) to stdout
- Include a cleanup trap for temp files
- Reference the script path as `/mnt/skills/user/{skill-name}/scripts/{script}.sh`

### Creating the Zip Package

After creating or updating a skill:

```bash
cd skills
zip -r {skill-name}.zip {skill-name}/
```

### End-User Installation

Document these two installation methods for users:

**Claude Code:**
```bash
cp -r skills/{skill-name} ~/.claude/skills/
```

**claude.ai:**
Add the skill to project knowledge or paste SKILL.md contents into the conversation.

If the skill requires network access, instruct users to add required domains at `claude.ai/settings/capabilities`.

# component-library

Re-usable components for multiple languages, platforms, and frameworks, by Digital Generalists. Components are organized by platform, then package; each package is self-contained with its own build configuration and reference implementation. The initial release contains the iOS `DGCoreUI` framework (Objective-C, UIKit) with the Tool Shelf and Presentation Cards components and a SwiftUI reference app. See `README.md` for component details.

## Project Structure

```
apple/ios/core-ui/    → DGCoreUI framework (Xcode project, framework source, ReferenceImplementation app)
  DGCoreUI/           →   Framework source: Toolshelf/, PresentationCards/, Notifications/, shared types and protocols
  ReferenceImplementation/ → SwiftUI app demonstrating each component
.agents/skills/       → Core skills (SKILL.md per directory)
.agents/agents/       → Reusable agent personas (code-reviewer, test-engineer, security-auditor)
.agents/hooks/        → Session lifecycle hooks
.agents/commands/     → Slash commands (/spec, /plan, /build, /test, /review, /code-simplify, /ship, /devcontainer)
.agents/references/   → Supplementary checklists (testing, performance, security, accessibility)
.agents/docs/         → Setup guides for different tools
.setup/               → Repo tooling (add-devcontainer.sh)
```

## Skills by Phase

**Define:** spec-driven-development
**Plan:** planning-and-task-breakdown
**Build:** incremental-implementation, test-driven-development, context-engineering, source-driven-development, frontend-ui-engineering, api-and-interface-design
**Verify:** browser-testing-with-devtools, debugging-and-error-recovery
**Review:** code-review-and-quality, code-simplification, security-and-hardening, performance-optimization
**Ship:** git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, shipping-and-launch

## Conventions

### Components

- New platforms and frameworks go in sibling directories at the matching level (e.g. `apple/macos/`, `android/`, `web/react/`)
- Every package is self-contained and ships a reference implementation demonstrating its components
- Every new component is added to the Components table in `README.md`, with its prerequisites, supported versions, and build steps
- DGCoreUI: public headers are listed in the `DGCoreUI.h` umbrella header and imported as `<DGCoreUI/...>`; Objective-C types use the `DG` prefix
- DGCoreUI: components own no content — the host supplies buttons, menus, cards, and styling
- DGCoreUI: any initializer taking a C configuration struct (not importable by Swift) needs a Swift-usable variant taking the values individually

### Skills

- Every skill lives in `skills/<name>/SKILL.md`
- YAML frontmatter with `name` and `description` fields
- Description starts with what the skill does (third person), followed by trigger conditions ("Use when...")
- Every skill has: Overview, When to Use, Process, Common Rationalizations, Red Flags, Verification
- References are in `references/`, not inside skill directories
- Supporting files only created when content exceeds 100 lines

## Commands

- `xcodebuild -project apple/ios/core-ui/DGCoreUI.xcodeproj -target DGCoreUI -configuration Debug -sdk iphonesimulator build` — Build the DGCoreUI framework
- `xcodebuild -project apple/ios/core-ui/DGCoreUI.xcodeproj -scheme ReferenceImplementation -destination 'generic/platform=iOS Simulator' build` — Build the reference app (and the framework it links)
- There are no automated tests yet; verify component changes by running the ReferenceImplementation app
- Validate skills: Check that all SKILL.md files have valid YAML frontmatter with name and description
- `./.setup/add-devcontainer.sh --list` — List the devcontainer stacks available from `shelterbelt/docker`
- `./.setup/add-devcontainer.sh <stack> [--full]` — Install a devcontainer config into `.devcontainer/`

## Boundaries

- Always: Follow the skill-anatomy.md format for new skills
- Never: Add skills that are vague advice instead of actionable processes
- Never: Duplicate content between skills — reference other skills instead

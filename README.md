# Component Library by Digital Generalists

*Re-usable components for multiple languages, platforms, and frameworks*

## What Is the Component Library

The Component Library is a collection of re-usable user interface and application components developed by [Digital Generalists](http://digitalgeneralists.com). Components are organized by platform and framework so that each one can be built, versioned, and included in an application independently of the others.

The library is intended to house components for multiple languages, platforms, and frameworks. The initial release contains iOS components written in Objective-C, packaged as the `DGCoreUI` framework, along with a SwiftUI reference implementation that demonstrates their use.

## Components

| Platform | Package | Language | Components |
|----------|---------|----------|------------|
| iOS | [`DGCoreUI`](apple/ios/core-ui) | Objective-C (Swift-compatible) | [Tool Shelf](#tool-shelf), [Presentation Cards](#presentation-cards) |

### iOS — DGCoreUI

`DGCoreUI` is an iOS framework built on UIKit. Its components are UIKit view controllers that can be hosted directly in a UIKit application or wrapped with `UIViewControllerRepresentable` for use in SwiftUI.

#### Tool Shelf

[`DGToolShelfViewController`](apple/ios/core-ui/DGCoreUI/Toolshelf/DGToolShelfViewController.h) displays a shelf of main menu buttons, each of which reveals a horizontally scrollable submenu of buttons. An optional favorites menu can be displayed in place of the main menu and submenus.

The shelf owns no menu content. The host application creates every button (including its image, title, target, and action), describes the menu structure with [`DGShelfMenuDefinition`](apple/ios/core-ui/DGCoreUI/Toolshelf/DGShelfMenuDefinition.h) instances, and supplies the visual styling. The shelf lays out, styles, and switches between the menus.

The shelf posts `UI_SAVE_UI_STATE` whenever the active menu or a menu's scroll position changes. To persist and restore that state, read the shelf as a [`DGToolShelfUIStateManagerProtocol`](apple/ios/core-ui/DGCoreUI/Toolshelf/DGToolShelfUIStateManagerProtocol.h) and pass the saved state back through the `state` parameter at initialization.

#### Presentation Cards

[`DGCardPresentationViewController`](apple/ios/core-ui/DGCoreUI/PresentationCards/DGCardPresentationViewController.h) presents a swipeable deck of cards over a dimmed background, such as an onboarding walkthrough or feature tour. Each card can highlight a region of the screen by cutting it out of the dimmed background.

Cards are [`DGPresentationCardViewController`](apple/ios/core-ui/DGCoreUI/PresentationCards/DGPresentationCardViewController.h) instances, or any view controller conforming to [`DGPresentationCardProtocol`](apple/ios/core-ui/DGCoreUI/PresentationCards/DGPresentationCardProtocol.h). A card can display text, an image, a custom view, or a custom view controller, and can post a notification when it becomes active. The presentation can be closed with a single dismiss button or with accept/decline buttons, and posts `UI_CARD_PRESENTATION_DISMISSED` once its exit animation finishes.

#### Shared Infrastructure

Both components are built on a small set of shared types that are also available to host applications:

- [`DGComponentTypeDefinitions.h`](apple/ios/core-ui/DGCoreUI/DGComponentTypeDefinitions.h) — the enumerations, notification names, and display configuration structures used across the framework
- [`DGSupportViewControllerProtocol`](apple/ios/core-ui/DGCoreUI/DGSupportViewControllerProtocol.h) — the common interface for attaching a support view (such as the tool shelf or card presentation) to a host and transitioning between its display modes
- [`DGNotificationManager`](apple/ios/core-ui/DGCoreUI/Notifications/DGNotificationManager.h) and [`DGNotificationObserver`](apple/ios/core-ui/DGCoreUI/Notifications/DGNotificationObserver.h) — context-aware registration for, and posting of, the notifications the components use to communicate with their hosts
- [`DGUIState`](apple/ios/core-ui/DGCoreUI/DGUIState.h) and the `DGUIState*Protocol` / `DGUIStateManager*Protocol` family — the UI state persistence contract

## Documentation

Each component is documented in its public headers. The [`DGCoreUI.h`](apple/ios/core-ui/DGCoreUI/DGCoreUI.h) umbrella header lists every public header in the framework, and the [reference implementation](#the-reference-implementation) demonstrates each component in a running application.

## License

The Component Library is released under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

See the [`LICENSE.txt`](LICENSE.txt) file for the formal license specification.

## Repository Layout

Components are grouped by vendor/platform, then by package. Each package is self-contained, with its own project files, build configuration, and reference implementation.

```
component-library/
├── apple/
│   └── ios/
│       └── core-ui/                       # DGCoreUI framework
│           ├── DGCoreUI.xcodeproj         #   Xcode project (framework + reference app)
│           ├── DGCoreUI/                  #   Framework source
│           │   ├── Notifications/         #     Notification manager and observer protocols
│           │   ├── PresentationCards/     #     Presentation Cards component
│           │   └── Toolshelf/             #     Tool Shelf component
│           └── ReferenceImplementation/   #   SwiftUI reference application
├── .agents/                               # AI coding agent skills, personas, commands, and references
├── .setup/                                # Repository tooling (add-devcontainer.sh)
└── LICENSE.txt
```

New platforms and frameworks are added as siblings at the appropriate level (for example, `apple/macos/`, `android/`, or `web/react/`).

## Prerequisites and Supported Versions

### iOS — DGCoreUI

#### Prerequisites

`DGCoreUI` is an iOS-specific framework. To build and use it, you need to have Xcode installed.

The provided Xcode project files are generated from Xcode 27.1.

* Xcode \[[download](https://developer.apple.com/xcode/)\]

Xcode should be the only prerequisite for using `DGCoreUI`. If you want to run the reference implementation on a device, you'll need an iOS device.

#### Supported Versions

| Target | Minimum iOS Version | Devices |
|--------|---------------------|---------|
| `DGCoreUI` framework | iOS 17.0 | iPhone, iPad |
| `ReferenceImplementation` app | iOS 27.0 | iPhone, iPad |

Mac Catalyst is not supported.

## Building

### Building DGCoreUI

To build the framework:

	Open apple/ios/core-ui/DGCoreUI.xcodeproj in Xcode
	Select the 'DGCoreUI' target
	Select the 'Debug' or 'Release' build configuration
	Select an iOS device or simulator destination
	Press 'Cmd+B'

The project provides the standard `Debug` and `Release` build configurations.

## Including DGCoreUI in an Application

To include `DGCoreUI` in an application:

- Create a new application via Xcode, or open an existing one
- Add `DGCoreUI.xcodeproj` to the application's project or workspace, or build the framework as described above
- Select the application target and click **General** in the editor window
- Find the **Frameworks, Libraries, and Embedded Content** section and click the **+** button
- Select **DGCoreUI.framework** and set it to **Embed & Sign**
- Import the framework in any source file that references an API, class, or protocol from it

  Objective-C:

		#import <DGCoreUI/DGCoreUI.h>

  Swift:

		import DGCoreUI

### Using DGCoreUI from Swift

The framework's display configurations (`DGToolShelfDisplayConfiguration` and `DGPresentationDisplayConfiguration`) are C structures holding object pointers, which Swift cannot import. Each component therefore provides an additional initializer that takes the configuration values individually.

To use a component from SwiftUI, wrap it in a `UIViewControllerRepresentable`:

	import SwiftUI
	import DGCoreUI

	struct PresentationCardView: UIViewControllerRepresentable {
	    let text: String

	    func makeUIViewController(context: Context) -> DGPresentationCardViewController {
	        DGPresentationCardViewController(text: text, textColor: .label, image: UIImage(named: "CardLogo"))
	    }

	    func updateUIViewController(_ uiViewController: DGPresentationCardViewController, context: Context) {
	        // The card is configured at initialization and has no mutable state to update.
	    }
	}

See the reference implementation for complete wrappers around the tool shelf and the card presentation, including building the shelf's menus and highlighting on-screen regions from presentation cards.

## The Reference Implementation

The [`ReferenceImplementation`](apple/ios/core-ui/ReferenceImplementation) application is a SwiftUI app that demonstrates including `DGCoreUI` in an application and should be used as guidance on how to incorporate the components.

The reference implementation:

- Wraps `DGToolShelfViewController` in [`ToolShelfView`](apple/ios/core-ui/ReferenceImplementation/ToolShelfView.swift), building draw, edit, shapes, and export menus — including a menu with more buttons than fit on screen, so that it scrolls — and managing radio-button-style active state for the draw tools
- Wraps `DGCardPresentationViewController` in [`CardPresentationView`](apple/ios/core-ui/ReferenceImplementation/PresentationCardView.swift), presenting a deck of cards that highlights the tool shelf and each of its main menu buttons
- Listens for `UI_CARD_PRESENTATION_DISMISSED` in [`ContentView`](apple/ios/core-ui/ReferenceImplementation/ContentView.swift) to remove the presentation once it closes

The reference implementation builds and links the framework directly from the same Xcode project. To run it:

	Open apple/ios/core-ui/DGCoreUI.xcodeproj in Xcode
	Select the 'ReferenceImplementation' scheme
	Select an iOS simulator or device destination
	Press 'Cmd+R'

## Contributing Components

When adding a new component:

- Place it under the appropriate platform and package directory, creating a new package if it does not belong in an existing one
- Keep the package self-contained, with its own build configuration
- Provide a reference implementation that demonstrates the component in a running application
- Add the component to the [Components](#components) table and document its prerequisites, supported versions, and build steps in this README

### Development Tooling

The repository includes engineering skills, agent personas, and slash commands for AI coding agents under [`.agents/`](.agents) (mirrored into `.claude/`, `.cursor/`, and `.opencode/`), based on the [`agent-skills`](https://github.com/addyosmani/agent-skills) project by Addy Osmani. These cover the development lifecycle — `/spec`, `/plan`, `/build`, `/test`, `/review`, `/code-simplify`, and `/ship`.

A devcontainer configuration for a tech stack can be installed with [`.setup/add-devcontainer.sh`](.setup/add-devcontainer.sh) (or the `/devcontainer` command), which pulls stack configurations from [`shelterbelt/docker`](https://github.com/shelterbelt/docker):

```bash
./.setup/add-devcontainer.sh --list          # see what's available
./.setup/add-devcontainer.sh <stack> --full  # install a stack into .devcontainer/
```

## Acknowledgments

The `DGCoreUI` components were originally developed for, and extracted from, Digital Generalists applications, including Spiral.

AI Acknowledgement: AI tooling was used to enhance existing implementations or fully implement components. Components completed prior to 2024 were originally written by hand.

*Copyright © 2012 - 2026 [Digital Generalists, LLC.](http://digitalgeneralists.com)*

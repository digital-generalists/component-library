import SwiftUI
import DGCoreUI

/// Reports where the shelf and its main-menu buttons are on screen, in window coordinates, so other UI (such
/// as the presentation cards) can highlight them. Pass the same instance to `ToolShelfView`.
///
/// The frames only exist once the shelf has been laid out, so they are read on demand rather than stored.
final class ToolShelfRegions {
    fileprivate weak var shelf: DGToolShelfViewController?
    fileprivate var menuButtons: [UIButton] = []

    /// The whole shelf, or `.zero` if it isn't on screen.
    var shelfRegion: CGRect {
        guard let view = shelf?.view else { return .zero }
        return view.convert(view.bounds, to: nil)
    }

    /// The main-menu buttons, in the order the menus were injected.
    var menuButtonRegions: [CGRect] {
        menuButtons.map { $0.convert($0.bounds, to: nil) }
    }
}

/// SwiftUI wrapper around the DGCoreUI `DGToolShelfViewController`.
///
/// The shelf owns no menu content: this wrapper builds every button (with its own action) and the menu
/// structure, and injects them along with the styling.
struct ToolShelfView: UIViewControllerRepresentable {
    /// Filled in with the shelf's on-screen frames, if provided.
    var regions: ToolShelfRegions? = nil

    /// Called with the name of a button when it's tapped.
    var onSelect: (String) -> Void = { _ in }

    final class Coordinator {
        weak var shelf: DGToolShelfViewController?
        var toolButtons: [UIButton] = []
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> DGToolShelfViewController {
        let coordinator = context.coordinator
        let onSelect = onSelect

        /// A button whose action is owned by the host. The shelf only lays it out and styles it.
        func makeButton(symbol: String, title: String, action: @escaping () -> Void = {}) -> UIButton {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(systemName: symbol), for: .normal)
            button.tintColor = .label
            button.accessibilityLabel = title
            button.addAction(UIAction { _ in
                onSelect(title)
                action()
            }, for: .touchUpInside)
            return button
        }

        // Draw tools behave like radio buttons; the host tells the shelf which one is active.
        func selectTool(_ selected: UIButton) {
            for button in coordinator.toolButtons {
                coordinator.shelf?.applyActiveState(button === selected, to: button)
            }
        }

        var pen: UIButton!
        var highlighter: UIButton!
        var eraser: UIButton!
        pen = makeButton(symbol: "pencil", title: "Pen") { selectTool(pen) }
        highlighter = makeButton(symbol: "highlighter", title: "Highlighter") { selectTool(highlighter) }
        eraser = makeButton(symbol: "eraser", title: "Eraser") { selectTool(eraser) }
        coordinator.toolButtons = [pen, highlighter, eraser]

        let undo = makeButton(symbol: "arrow.uturn.backward", title: "Undo")
        let redo = makeButton(symbol: "arrow.uturn.forward", title: "Redo")
        let clear = makeButton(symbol: "trash", title: "Clear")

        let exportPDF = makeButton(symbol: "doc.richtext", title: "Export PDF")
        let exportImage = makeButton(symbol: "photo", title: "Export Image")

        // More buttons than fit in a submenu (7), so the menu scrolls horizontally.
        let shapes: [(symbol: String, title: String)] = [
            ("circle", "Circle"), ("square", "Square"), ("triangle", "Triangle"), ("diamond", "Diamond"),
            ("star", "Star"), ("heart", "Heart"), ("hexagon", "Hexagon"), ("pentagon", "Pentagon"),
            ("octagon", "Octagon"), ("capsule", "Capsule"), ("oval", "Oval"), ("seal", "Seal")
        ]
        let shapeButtons = shapes.map { makeButton(symbol: $0.symbol, title: $0.title) }

        let drawMenuButton = makeButton(symbol: "pencil.tip", title: "Draw Menu")
        let editMenuButton = makeButton(symbol: "square.and.pencil", title: "Edit Menu")
        let shapesMenuButton = makeButton(symbol: "square.on.circle", title: "Shapes Menu")
        let exportMenuButton = makeButton(symbol: "square.and.arrow.up", title: "Export Menu")

        let menus: [DGShelfMenuDefinition] = [
            DGShelfMenuDefinition(
                name: "drawMenu",
                menuButton: drawMenuButton,
                buttons: [pen, highlighter, eraser]
            ),
            // Tapping these performs an action rather than changing a mode, so a double tap isn't meaningful.
            DGShelfMenuDefinition(
                name: "editMenu",
                menuButton: editMenuButton,
                buttons: [undo, redo, clear],
                buttonsIgnoringDoubleTap: [undo, redo, clear]
            ),
            DGShelfMenuDefinition(
                name: "shapesMenu",
                menuButton: shapesMenuButton,
                buttons: shapeButtons,
                buttonsIgnoringDoubleTap: shapeButtons
            ),
            DGShelfMenuDefinition(
                name: "exportMenu",
                menuButton: exportMenuButton,
                buttons: [exportPDF, exportImage],
                buttonsIgnoringDoubleTap: [exportPDF, exportImage]
            )
        ]

        // The container builds its own views, so it doesn't need a host view controller. The container
        // view controller is only used as the shelf's notification context.
        let shelf = DGToolShelfViewController(
            host: nil,
            containerViewController: UIViewController(),
            menus: menus,
            favoritesMenu: nil,
            state: nil,
            mainBackgroundColor: .secondarySystemBackground,
            activeSubBackgroundColor: .systemBackground,
            activeSubBorderColor: .separator,
            contentBackgroundColor: .secondarySystemBackground,
            contentButtonBorderColor: .separator,
            activeContentButtonBorderColor: .tintColor,
            textColor: .label,
            reservedLeftBorderWidth: 0,
            reservedRightBorderWidth: 0,
            mainMenuNumberOfVisibleButtons: 6,
            submenuNumberOfVisibleButtons: 7
        ) ?? DGToolShelfViewController()
        coordinator.shelf = shelf
        regions?.shelf = shelf
        regions?.menuButtons = [drawMenuButton, editMenuButton, shapesMenuButton, exportMenuButton]

        // Load the view so the menus exist, then mark the initial tool as active.
        _ = shelf.view
        selectTool(pen)
        return shelf
    }

    func updateUIViewController(_ uiViewController: DGToolShelfViewController, context: Context) {
        // The shelf is configured at initialization and has no mutable state to update.
    }
}

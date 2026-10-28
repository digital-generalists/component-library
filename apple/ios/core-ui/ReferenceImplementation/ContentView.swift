import SwiftUI
import DGCoreUI
import Playgrounds

struct ContentView: View {
    @State private var isShowingCard = false
    @State private var lastSelection = "Tap a tool shelf button"
    // Reports where the shelf and its main-menu buttons are, so the cards can highlight them.
    @State private var shelfRegions = ToolShelfRegions()

    var body: some View {
        // The presentation is a full-screen sibling of the button (not an overlay on it), so the dialog is
        // inside its parent's bounds and receives touches.
        ZStack {
            VStack {
                // The interface never rotates and only the shelf's icons turn to match the device.
                ToolShelfView(regions: shelfRegions) { lastSelection = $0 }
                    .frame(height: 88)

                Spacer()

                Button("Show Presentation Cards") {
                    isShowingCard = true
                }
                .padding()

                Text(lastSelection)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            if isShowingCard {
                // The safe-area-ignoring reader makes the presentation full screen, which is the window
                // coordinate space the shelf's regions are reported in.
                GeometryReader { _ in
                    CardPresentationView(cards: Self.cards(highlighting: shelfRegions))
                }
                .ignoresSafeArea()
            }
        }
        // The container posts this notification once its exit animation finishes.
        .task(id: isShowingCard) {
            guard isShowingCard else { return }
            for await _ in NotificationCenter.default.notifications(named: Foundation.Notification.Name(UI_CARD_PRESENTATION_DISMISSED)) {
                isShowingCard = false
                break
            }
        }
    }

    /// Cards that start and finish with the background fully dimmed, and in between highlight the whole
    /// tool shelf and then each of its main-menu buttons.
    private static func cards(highlighting regions: ToolShelfRegions) -> [CardPresentationView.Card] {
        // Descriptions in the order the shelf's menus were injected.
        let menuDescriptions = [
            "Draw: choose a pen, highlighter or eraser.",
            "Edit: undo, redo or clear.",
            "Shapes: a longer menu that scrolls horizontally.",
            "Export: save as a PDF or an image."
        ]

        var cards = [
            CardPresentationView.Card(text: "Welcome to DGCoreUI. Swipe to see the highlighted areas.", image: UIImage(named: "CardLogo")),
            CardPresentationView.Card(text: "This is the tool shelf. The top row picks a menu, and the row below shows that menu's buttons.", highlightRegion: regions.shelfRegion)
        ]
        for (description, region) in zip(menuDescriptions, regions.menuButtonRegions) {
            cards.append(CardPresentationView.Card(text: description, highlightRegion: region))
        }
        cards.append(CardPresentationView.Card(text: "Tap Got It to close the presentation."))
        return cards
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}

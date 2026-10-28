import SwiftUI
import DGCoreUI

/// SwiftUI wrapper around the DGCoreUI `DGPresentationCardViewController`.
struct PresentationCardView: UIViewControllerRepresentable {
    let text: String
    var textColor: UIColor = .label
    var image: UIImage? = UIImage(named: "CardLogo")

    func makeUIViewController(context: Context) -> DGPresentationCardViewController {
        DGPresentationCardViewController(text: text, textColor: textColor, image: image)
    }

    func updateUIViewController(_ uiViewController: DGPresentationCardViewController, context: Context) {
        // The card is configured at initialization and has no mutable state to update.
    }
}

/// SwiftUI wrapper around the DGCoreUI `DGCardPresentationViewController`, loaded with a deck of
/// `DGPresentationCardViewController` instances.
struct CardPresentationView: UIViewControllerRepresentable {
    /// Content for one card. A non-empty `highlightRegion` (in the presentation's coordinate space) is cut out
    /// of the dimmed background while the card is showing; `.zero` leaves the background fully dimmed.
    struct Card {
        let text: String
        var image: UIImage? = nil
        var highlightRegion: CGRect = .zero
    }

    let cards: [Card]
    var buttonTypes: DGCardPresentationButtonTypes = DGCardPresentationButtonTypesDismiss

    func makeUIViewController(context: Context) -> DGCardPresentationViewController {
        let cards = cards.map {
            DGPresentationCardViewController(text: $0.text, textColor: .label, image: $0.image, highlightRegion: $0.highlightRegion)
        }
        // The container builds its own views, so it doesn't need a host view controller.
        let presentation = DGCardPresentationViewController(
            host: nil,
            presentationCards: cards as [Any],
            backgroundColor: UIColor.black.withAlphaComponent(0.6),
            pageIndicatorTintColor: .lightGray,
            currentPageIndicatorTintColor: .darkGray,
            textColor: .tintColor,
            highlightedTextColor: .systemBlue,
            topOffset: 0,
            statusBarHeight: 0,
            buttonTypes: buttonTypes
        )
        // Dim the background behind the dialog.
        presentation?.transition(to: DGSupportViewModeDisabledBackground)
        return presentation ?? DGCardPresentationViewController()
    }

    func updateUIViewController(_ uiViewController: DGCardPresentationViewController, context: Context) {
        // The presentation is configured at initialization and has no mutable state to update.
    }
}

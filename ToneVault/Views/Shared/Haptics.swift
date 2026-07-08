import UIKit

/// Thin wrapper around UIFeedbackGenerator. Safe no-ops on devices without haptics.
enum Haptics {
    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }
}

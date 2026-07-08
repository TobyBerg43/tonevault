import SwiftUI

extension View {
    /// Attaches a gesture only when `enabled` is true; otherwise leaves the view
    /// untouched (so read-only control boards don't intercept scrolling).
    @ViewBuilder
    func gestureIf<G: Gesture>(_ enabled: Bool, _ gesture: G) -> some View {
        if enabled {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

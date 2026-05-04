import SwiftUI

/// "Liquid Glass" surface treatment for floating UI (tab bar, session pill,
/// floating buttons). Currently uses `.ultraThinMaterial` + a 0.5pt rim
/// highlight, which approximates the iOS 26 Liquid Glass look on iOS 17/18.
///
/// When we adopt the iOS 26 SDK, swap the implementation to call the native
/// `.glassEffect(.regular, in:)` modifier instead — keep the public surface
/// (`.liquidGlass(in:)`) stable so call sites don't change.
extension View {
    func liquidGlass<S: Shape>(in shape: S) -> some View {
        self
            .background {
                shape.fill(.ultraThinMaterial)
            }
            .overlay {
                shape.stroke(Color.white.opacity(0.18), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

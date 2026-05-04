import SwiftUI
import UIKit

/// Hex parser used by both legacy callers and the new token system.
/// Supports 6-digit hex (`#RRGGBB`).
extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var raw: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&raw)
        let r, g, b: UInt64
        switch trimmed.count {
        case 6: (r, g, b) = (raw >> 16, raw >> 8 & 0xFF, raw & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}

// MARK: - Dynamic helpers

private func dyn(_ light: UIColor, _ dark: UIColor) -> Color {
    Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? dark : light
    })
}

private func uic(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
    UIColor(
        red:   CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >>  8) & 0xFF) / 255,
        blue:  CGFloat( hex        & 0xFF) / 255,
        alpha: alpha
    )
}

/// Semantic color tokens for Eyescape's warm dual-mode theme.
///
/// All tokens auto-switch with `UITraitCollection.userInterfaceStyle`,
/// so consumers don't read `@Environment(\.colorScheme)` themselves.
///
/// Light: cream/oat background + warm near-black text + terracotta amber + deep moss sage.
/// Dark : warm-espresso background + cream text + peach amber + light moss sage.
extension Color {

    // ── Surfaces ────────────────────────────────────────────────────
    static let appBackground   = dyn(uic(0xFAF6ED), uic(0x16110D))
    static let appSurface      = dyn(uic(0xFFFFFF), uic(0x1F1812))
    static let appSurfaceElev  = dyn(uic(0xF1E9D8), uic(0x2B231B))

    // ── Text ────────────────────────────────────────────────────────
    static let textPrimary     = dyn(uic(0x1F1815), uic(0xF4ECDF))
    static let textSecondary   = dyn(uic(0x837569), uic(0x998875))
    static let textTertiary    = dyn(uic(0xB5A99B), uic(0x5E5246))

    // ── Accents ─────────────────────────────────────────────────────
    static let accentAmber       = dyn(uic(0xC5631E), uic(0xE89B6A))
    static let accentAmberSoft   = dyn(uic(0xC5631E, alpha: 0.10), uic(0xE89B6A, alpha: 0.13))
    static let accentAmberBorder = dyn(uic(0xC5631E, alpha: 0.22), uic(0xE89B6A, alpha: 0.28))

    static let accentSage        = dyn(uic(0x5F7E4F), uic(0xA8C58B))
    static let accentSageSoft    = dyn(uic(0x5F7E4F, alpha: 0.10), uic(0xA8C58B, alpha: 0.13))
    static let accentSageBorder  = dyn(uic(0x5F7E4F, alpha: 0.24), uic(0xA8C58B, alpha: 0.30))

    // ── Hairlines ───────────────────────────────────────────────────
    static let hairline       = dyn(uic(0x1F1815, alpha: 0.06), uic(0xF4ECDF, alpha: 0.07))
    static let hairlineStrong = dyn(uic(0x1F1815, alpha: 0.10), uic(0xF4ECDF, alpha: 0.13))

    // ── Status ──────────────────────────────────────────────────────
    static let appError       = dyn(uic(0xB0413E), uic(0xD9665E))

    // ── Category palette (Insights stacked bars) ───────────────────
    static let catSocial         = dyn(uic(0xC5631E), uic(0xE89B6A))
    static let catEntertainment  = dyn(uic(0xD9956B), uic(0xE8B58F))
    static let catProductivity   = dyn(uic(0x5F7E4F), uic(0xA8C58B))
    static let catGames          = dyn(uic(0x8B5E83), uic(0xB68FAE))
    static let catCreativity     = dyn(uic(0x6B7C8E), uic(0x97A8BA))
    static let catOther          = dyn(uic(0xB5A99B), uic(0x5E5246))
}

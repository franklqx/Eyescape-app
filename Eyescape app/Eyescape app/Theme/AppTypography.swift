import SwiftUI

/// Pre-configured text styles used across Eyescape.
///
/// These wrap `.system` fonts with the right size/weight/letterspacing/numerics
/// so callers don't repeat the same font modifier chain six times. Every
/// numeric-heavy style enables `.tabularNumbers` so digits column-align
/// without a monospaced-typewriter feel.
struct AppText: ViewModifier {
    let style: AppTextStyle

    func body(content: Content) -> some View {
        switch style {
        case .pageTitle:
            content
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.6)
        case .greeting:
            content
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.6)
        case .subHeader:
            content
                .font(.system(size: 12, weight: .medium))
                .tracking(-0.1)
        case .heroValue:
            content
                .font(.system(size: 48, weight: .semibold))
                .tracking(-1.5)
                .monospacedDigit()
        case .heroValueLarge:
            content
                .font(.system(size: 56, weight: .semibold))
                .tracking(-1.8)
                .monospacedDigit()
        case .heroUnit:
            content
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.6)
        case .statValue:
            content
                .font(.system(size: 18, weight: .semibold))
                .tracking(-0.4)
                .monospacedDigit()
        case .statValueLarge:
            content
                .font(.system(size: 22, weight: .semibold))
                .tracking(-0.5)
                .monospacedDigit()
        case .statLabel:
            content
                .font(.system(size: 10, weight: .medium))
                .tracking(-0.1)
        case .sectionLabel:
            content
                .font(.system(size: 11, weight: .semibold))
                .tracking(-0.1)
        case .body:
            content
                .font(.system(size: 14))
                .tracking(-0.2)
        case .caption:
            content
                .font(.system(size: 12))
                .tracking(-0.1)
        case .captionStrong:
            content
                .font(.system(size: 12, weight: .semibold))
                .tracking(-0.1)
        case .countdown:
            content
                .font(.system(size: 60, weight: .thin))
                .tracking(-2)
                .monospacedDigit()
        case .tabLabel:
            content
                .font(.system(size: 10, weight: .medium))
                .tracking(-0.1)
        case .pillAction:
            content
                .font(.system(size: 12, weight: .semibold))
                .tracking(-0.1)
        }
    }
}

enum AppTextStyle {
    case pageTitle, greeting, subHeader
    case heroValue, heroValueLarge, heroUnit
    case statValue, statValueLarge, statLabel
    case sectionLabel
    case body, caption, captionStrong
    case countdown
    case tabLabel, pillAction
}

extension View {
    func appText(_ style: AppTextStyle) -> some View {
        modifier(AppText(style: style))
    }
}

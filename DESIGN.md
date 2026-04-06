# Eyescape Design System

iOS app for the 20-20-20 eye health rule. Target: iPhone 14 Pro+. Aesthetic: precision instrument, not wellness fluff. Dark, calm, amber-accented.

---

## Color Tokens

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0C0C10` | Full-screen background, `ignoresSafeArea` |
| `surface` | `#18181F` | Card backgrounds, tab bar |
| `surfaceElevated` | `#22222C` | Active session card, pill group backgrounds |
| `textPrimary` | `#F2F2F5` | Headings, values, primary text |
| `textSecondary` | `#8A8A96` | Labels, subtitles, secondary actions |
| `amber` | `#E8954A` | Accent: CTAs, section labels, active state dot, ambient glow |
| `amberDim` | `#E8954A` at 12% opacity | Card backgrounds behind amber content |
| `amberBorder` | `#E8954A` at 20-25% opacity | Card strokes on amber-tinted surfaces |
| `error` | `#E05454` | Destructive actions (Stop), error states |
| `border` | `white` at 7% opacity | Default card stroke |

---

## Typography Scale

All type is SF Pro (`.system`). Monospaced label pattern uses `.monospaced` design variant.

| Role | Size | Weight | Design | Tracking | Usage |
|------|------|--------|--------|----------|-------|
| Page title | 28pt | `.semibold` | default | — | Screen headers (Home greeting, Preferences, Your eye health) |
| Modal title | 22pt | `.semibold` | default | — | BreakView "Rest for 20 seconds" |
| Countdown | 52pt | `.thin` | `.monospaced` | — | BreakView timer — unique, no other 52pt |
| Stat value | 24pt | `.regular` | `.monospaced` | — | AnalyticsView StatCard |
| Stat mini | 18pt | `.regular` | `.monospaced` | — | HomeView StatMiniCard |
| Price | 34pt | `.bold` | `.rounded` | — | PaywallView price display |
| CTA primary | 16-17pt | `.semibold` | default | — | "Start session", "Get Eyescape Pro", "Done" |
| Body | 14-15pt | `.regular` | default | — | Subtitles, descriptions |
| Caption | 12-13pt | `.regular` | default | — | Card body, feature row subtitles |
| Section label | 10-11pt | `.medium` | `.monospaced` | 1.2 | "TODAY", "SESSION", "INSIGHTS" — always UPPERCASE |
| Tag/pill | 8-10pt | `.bold`/`.medium` | `.monospaced` | — | "PRO" badge, pill group options |

---

## Spacing

| Name | Value | Usage |
|------|-------|-------|
| screenPadding | 24pt | Horizontal padding for all scroll content |
| cardPadding | 12-16pt | Inner card padding |
| stackSpacing | 24-40pt | Section spacing between major blocks |
| tabBarBottom | 28pt | Tab bar bottom padding (home indicator clearance) |
| diClearance | 60pt | Top clearance for Dynamic Island |

---

## Corner Radius

| Name | Value | Usage |
|------|-------|-------|
| card | 14-16pt | Standard cards (SettingsCard, StatCard, session cards) |
| button | 14pt | Standard buttons |
| paywallButton | 16pt | PaywallView CTA |
| pill | 6pt | Pill group option buttons |
| logo | `size * 0.25` | AmberGlowLogo rounded rect |

---

## Components

### AmberGlowLogo
Defined in `PaywallView.swift`. Reusable at any size.
- Dark amber-tinted rounded rect (`amber` at 12% opacity)
- Solid amber circle at `size * 0.35` diameter
- Double shadow: tight (`radius: size * 0.08`) + wide (`radius: size * 0.22`, opacity 0.4)

### StatMiniCard
Small 3-up metric cards on HomeView. Left-aligned, monospaced value + small label.

### StatCard
2x2 grid metric cards on AnalyticsView. Larger value, optional unit, amber accent variant.

### InsightCard
AI insight cards on AnalyticsView. Amber left-border (2pt), amber dot + title, body text with left padding.

### SettingsCard / SettingsRow / PillGroup
Settings section container, row with label/subtitle/trailing view, segmented pill selector.

### AmberGlowLogo
Reusable logo component. Use in: PaywallView hero, onboarding (future), About section.

---

## Animation Principles

- **BreakView focal dot**: `easeInOut(duration: 3).repeatForever(autoreverses: true)` scale 1.0→1.3. Mimics slow breath. The only prominent animation in the app.
- **Countdown**: `.contentTransition(.numericText(countsDown: true))` with `.animation(.default)`.
- **All other transitions**: SwiftUI defaults (no custom). Keep it calm.
- **No decorative motion**: blobs, floating elements, parallax — none.
- **Pet animation exemption**: Frame animations inside `PetView` (breathing, blinking, sleeping, mood transitions) are functional feedback, not decoration — they communicate eye health state. Not subject to the no-decorative-motion rule. All other UI areas remain motion-free.

---

## Voice & Copy

- Greeting: time-aware ("Good morning.", "Good afternoon.", "Good evening.", "Good night.")
- Instruction copy: direct, second-person ("Look at something 20 feet away.")
- Stats: metric labels in UPPERCASE monospaced ("TODAY", "BREAK RATE")
- Buttons: action-first ("Start session", "Take break", "Skip this break")
- Error copy: specific, actionable ("No previous purchases found." not "An error occurred.")

---

## Platform Constraints

- **Target**: iPhone 14 Pro+ only (Dynamic Island required)
- **Min OS**: iOS 17+ (Live Activities, SwiftData, `@Observable`)
- **Orientation**: Portrait only
- **Touch targets**: 44pt minimum (watch PaywallView close button, BreakView skip button)
- **Dark mode**: Dark only — no light mode variant

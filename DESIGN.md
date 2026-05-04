# Eyescape Design System (v2)

iOS app for the 20-20-20 eye health rule. Target: iPhone 14 Pro+. Aesthetic: warm dual-mode, calm, evidence-led — not "developer-tool" cold.

---

## Direction

> **Direction B — warm dual-mode + Liquid Glass.**
> Cream-on-cream for daylight reading, warm-espresso for night use. One refined amber accent (terracotta/peach), one sage second color reserved for "rest / completed / compliant" semantics. SF Pro default with `tabular-nums` for digits — no monospaced-typewriter feel.

Apple's iOS 26 *Liquid Glass* is used for floating UI (tab bar, session pill). On iOS 17/18 we fall back to `.ultraThinMaterial` + a 0.5pt rim highlight via the `liquidGlass(in:)` view modifier.

---

## Color Tokens

All tokens are dynamic — they switch automatically based on `UITraitCollection.userInterfaceStyle`. Source: `Theme/AppColors.swift`. Consumers reference `Color.tokenName` and never read `colorScheme` directly.

### Surfaces

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `appBackground`  | `#FAF6ED` (warm oat)        | `#16110D` (warm espresso, not pure black) | full-screen `ignoresSafeArea` |
| `appSurface`     | `#FFFFFF`                   | `#1F1812`                                  | cards, settings rows |
| `appSurfaceElev` | `#F1E9D8`                   | `#2B231B`                                  | active session card, segmented control track, exercise pill background |

### Text

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `textPrimary`   | `#1F1815` | `#F4ECDF` | headings, hero values |
| `textSecondary` | `#837569` | `#998875` | labels, subtitles |
| `textTertiary`  | `#B5A99B` | `#5E5246` | empty-state placeholders, chevrons |

### Accents

| Token | Light | Dark | Semantics |
|-------|-------|------|-----------|
| `accentAmber`       | `#C5631E` (terracotta) | `#E89B6A` (peach amber) | primary CTAs, active state, warning hero (long sessions ≥ 20 min) |
| `accentAmberSoft`   | amber × 10% alpha       | amber × 13% alpha        | soft accent fills behind amber content |
| `accentAmberBorder` | amber × 22% alpha       | amber × 28% alpha        | strokes on amber-tinted surfaces |
| `accentSage`        | `#5F7E4F` (deep moss)   | `#A8C58B` (light moss)   | "compliant / completed / healthy" hero |
| `accentSageSoft`    | sage × 10% alpha        | sage × 13% alpha         | soft fills behind sage content |
| `accentSageBorder`  | sage × 24% alpha        | sage × 30% alpha         | strokes on sage-tinted surfaces |

### Hairlines & status

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `hairline`       | `#1F1815` × 6%  | `#F4ECDF` × 7%  | row dividers, sub-stat verticals |
| `hairlineStrong` | `#1F1815` × 10% | `#F4ECDF` × 13% | hero ring background track |
| `appError`       | `#B0413E`       | `#D9665E`       | destructive (Stop), error state |

### Category palette

Used in Insights stacked-by-category bars and category dot markers. Stays inside the warm palette so the chart doesn't fight the rest of the UI.

| Category | Light | Dark |
|----------|-------|------|
| Social        | `#C5631E` | `#E89B6A` (= amber) |
| Entertainment | `#D9956B` | `#E8B58F` (peach) |
| Productivity  | `#5F7E4F` | `#A8C58B` (= sage) |
| Games         | `#8B5E83` | `#B68FAE` (muted plum) |
| Creativity    | `#6B7C8E` | `#97A8BA` (slate blue) |
| Other         | `#B5A99B` | `#5E5246` |

---

## Typography Scale

All type is `.system` (SF Pro). Numeric-heavy styles use `.monospacedDigit()` for column alignment — not monospaced typeface.

Source: `Theme/AppTypography.swift`. Apply via `.appText(.styleName)`.

| Style key | Size | Weight | Tracking | Notes |
|-----------|------|--------|----------|-------|
| `pageTitle`       | 28pt | semibold | -0.6 | "Your eye health", "Preferences" |
| `greeting`        | 28pt | semibold | -0.6 | "Good afternoon." |
| `subHeader`       | 12pt | medium   | -0.1 | "Today's longest session", date row |
| `heroValue`       | 48pt | semibold | -1.5 | Home hero |
| `heroValueLarge`  | 56pt | semibold | -1.8 | Insights hero, app-detail hero |
| `heroUnit`        | 22pt | medium   | -0.6 | "h" / "m" / "s" trailing units |
| `statValue`       | 18pt | semibold | -0.4 | Home sub-stats |
| `statValueLarge`  | 22pt | semibold | -0.5 | Insights sub-stats |
| `statLabel`       | 10pt | medium   | -0.1 | "Total" / "Avg pickup" |
| `sectionLabel`    | 11pt | semibold | -0.1 | UPPERCASE section eyebrow ("RECOMMENDED NOW") |
| `body`            | 14pt | regular  | -0.2 | row labels, instruction copy |
| `caption`         | 12pt | regular  | -0.1 | row subtitles, footnotes |
| `captionStrong`   | 12pt | semibold | -0.1 | "More" link, range tab labels |
| `countdown`       | 60pt | thin     | -2.0 | the **only** big timer number — BreakView, exercise session |
| `tabLabel`        | 10pt | medium   | -0.1 | floating tab bar |
| `pillAction`      | 12pt | semibold | -0.1 | session-pill action right edge |

---

## Spacing & layout

| Name            | Value | Usage |
|-----------------|-------|-------|
| screen padding  | 22pt  | horizontal padding for all scroll content |
| section gap     | 24-28pt | between major HomeView / Insights blocks |
| card padding    | 16-18pt | inside surface cards |
| stat divider gap| 14pt  | vertical padding around inline sub-stats strip |
| DI clearance    | 50pt  | top of every screen, accounts for Dynamic Island |
| pill clearance  | 96pt  | bottom of HomeView body, leaves room for floating session pill |
| tab bar inset   | 16pt  | gap from screen edges to floating tab bar |

---

## Corner radii

| Name  | Value | Usage |
|-------|-------|-------|
| pill  | `Capsule()` | floating session pill, range tabs, action buttons inside pill |
| card  | 18-22pt    | surface cards (recommendation, settings) |
| chip  | 14pt       | exercise duration pills, secondary buttons |
| rim   | 28pt       | floating Liquid Glass tab bar — `RoundedRectangle(cornerRadius: 28, style: .continuous)` |

---

## Components

### LiquidGlassTabBar
Defined in `Views/RootView.swift`. Floating capsule, 16pt edge gap, 64pt height, fixed at the bottom. Three tabs: Home / Insights / Settings. Active tab gets `accentAmberSoft` pill behind icon + label.

### Session pill (Home)
44pt-tall floating capsule at the bottom of HomeView, sitting just above the tab bar. State-aware:
- idle: dim amber dot + "Auto-protect off" + "Start" action
- active: amber dot + "Auto-protecting your eyes" + "Pause" — sage-tinted dot when `isCompliantDay`
- alerting: amber pulse + "Time for a break" + "Take it"
- paused: dim amber dot + "Paused" + "Resume"

### Hero block
Two flavors:
- **Home**: 48pt longest-session value, sage when compliant, amber when ≥20 min, ring on the right showing today's compliance %
- **Insights / category / app**: 56pt longest-session value with footnote line ("All sessions stayed under 20 min" / "78% longer than weekly avg")

### Sub-stats strip
Three values inline, hairline-divided, no card border. Replaces the 2×2 stat-card grid.

### Recommendation card
One contextual exercise with a one-sentence reason ("You just had a 42-min stretch — give your ciliary muscles a break"). Sage variant on compliant days ("Day's looking good. Keep blinking…"). Below: row list of the other 2 exercises.

### Range picker
Capsule segmented control: Day / Week / Month. Active segment is `appSurface` with light shadow; inactive is just text on `appSurfaceElev`. Replaces the previous static "This week" tag.

### Stacked weekly chart
Per-day bar, segmented vertically by category color. Today's bar gets a 2pt outline + bold day label.

---

## Animation principles

- **Breathing focal dot** (BreakView, exercise session): `easeInOut(duration: 3).repeatForever(autoreverses: true)` scale 1.0 → 1.3. Reused across screens — the only signature motion in the app.
- **Countdown**: `.contentTransition(.numericText(countsDown: true))` with `.animation(.default)`.
- **Tab switch**: `.snappy(duration: 0.18)` on `selected` change.
- **No decorative motion** elsewhere. No blobs floating around, no parallax, no shimmering.

---

## Voice & copy

- Greeting is time-aware: "Good morning." / "Good afternoon." / "Good evening." / "Good night."
- Direct, second-person instruction: "Look at something 20 feet away."
- Recommendation reasons cite the actual data: "You just had a 42-min stretch — …"
- Compliant day uses celebratory but understated: "Day's looking good. Keep blinking — slow blinks help the tear film stay even."
- Stats labels are short and lowercase-friendly: "Total", "Avg pickup", "Compliance" (NOT all-caps yelling like the v1 design).
- Errors are specific and actionable, never "An error occurred."

### What we never say
- ❌ "Treat / cure / fix near-sightedness"
- ❌ "Replace your glasses"
- ❌ Any reference to Bates Method or eye-rolling exercises (AAO doesn't recommend; can cause solar retinal injury if practiced outside)

---

## Platform constraints

- **Target**: iPhone 14 Pro+ (Dynamic Island required for the LA design)
- **Min OS**: iOS 17 (SwiftData, `@Observable`, Live Activities)
- **Liquid Glass native API**: iOS 26 only — `.ultraThinMaterial` fallback below
- **Orientation**: portrait only
- **Touch targets**: 44pt minimum
- **Color modes**: light + dark, both first-class — every token has both values

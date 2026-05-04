# Eyescape v2 Roadmap

> **Product Vision (v2 redirected, 2026-05)**: Eyescape is a serious eye-care
> companion. It surfaces the screen-time signals you actually need ("how long
> have you been on this without a break?"), enforces 20-20-20, and gives you
> evidence-based eye exercises you can launch in two taps. Apple Screen Time
> shows you data; Eyescape changes behaviour.

> Originally v2 was the digital-pet system. Pet-related design and code now
> live under "Parking Lot" at the bottom of this file. SwiftData schema and
> the existing pet engine are preserved so v1 users can upgrade safely, but
> all UI entry points have been removed.

---

## Phase 1 — Screen Time + 20-20-20 + Eye Exercises (v2.0)
**Goal**: ship a real eye-care app, not a toy.

### Foundations (done in this branch)
- [x] **Pet system frozen** — UI removed, code preserved (RootView / HomeView / EyescapeWidgetLiveActivity / Eyescape_appApp wiring all stripped of pet references; Models/PetState.swift, Features/PetMoodEngine.swift, Features/PetNotificationManager.swift, Views/PetView.swift retained as dead code).
- [x] **Local pickup tracking** — new `PickupSession` SwiftData model, populated by `SessionManager.handleForeground/handleBackground` with sub-5-second debounce. Added to schema list.
- [x] **ScreenTimeAggregator** — pure Swift functions for today's total / pickup count / average pickup / longest pickup / 20-min compliance / exercises / break-take rate. Unit-tested in `ScreenTimeAggregatorTests`.
- [x] **Eye exercise library** — three evidence-based routines:
  - 2 min Quick rest (20-20-20 + active blinks · AAO/AOA)
  - 3 min Palming (PubMed PMC4932063)
  - 5 min Classic exercise (PRC MoE 2008 official, A-grade in 2023 中西医结合诊疗指南)
- [x] **EyeExerciseSession view** — full-screen runner reusing the BreakView breathing-dot animation; writes `EyeExerciseRecord` only on full completion.
- [x] **HomeView 3-segment rewrite** — top: 4-card stats grid (today total / avg pickup / 20-min compliance / exercises today); middle: ExerciseCard with 3 length pills; bottom: SessionStatusBar with state-aware dot + Start/Pause/Resume. Auto-starts the protect session on appear.
- [x] **AnalyticsView fixes** — `["M","Tu","W","Th","F","Sa","Su"]` for the weekly chart, accessibility labels per bar, "This week" pseudo-button replaced with a static range label.
- [x] **ScreenTimeAuthManager** — wraps FamilyControls authorization, exposes `.notDetermined / .denied / .approved`. Wired into Settings as a "Connect Screen Time" CTA.
- [x] **DeviceActivityReport extension scaffold** — `EyescapeReportExtension.swift`, `DailyActivityReport.swift`, `DailyActivityView.swift`, `Info.plist` staged in `DeviceActivityReportExtension/`. Need Xcode UI to create the actual target.

### What's left for v2.0 ship
- [ ] **Xcode UI work** (per `docs/family-controls-application.md`):
  - Add Family Controls capability on main target.
  - Create the Device Activity Report extension target, drop in the staged files.
  - Configure App Group `group.com.eyescape.shared`.
  - Wire the `DeviceActivityReport(.daily, filter:)` embed into AnalyticsView.
- [ ] **Real-device QA on paid developer account** (sideload, no entitlement approval needed at this stage).
- [ ] **Submit Family Controls entitlement application** (main app + extension together, from Account Holder).
- [ ] **TestFlight after entitlement granted**.

### v2.1 polish
- [ ] **AnalyticsView range picker** — Day / Week / Month real toggle (currently a static "LAST 7 DAYS" tag).
- [ ] **AI insights v2** — replace the existing rule engine with insights derived from PickupSession + ExerciseRecord (eg. "your evenings run long — try a 2-min Quick rest at 8pm").
- [ ] **Onboarding** — first-launch flow that explains 20-20-20, walks through Family Controls authorization, sets reminder interval. Currently the user lands directly on HomeView.
- [ ] **a11y sweep** — finish what TODOS.md flagged.

### v2.2 deeper integration
- [ ] **DeviceActivityMonitor extension** — fire 20-20-20 alerts based on system-wide usage (not just Eyescape's own foreground time). Requires the same entitlement; piggyback on the existing application.
- [ ] **App-specific compliance** — surface the 3 apps you use most often without a 20-min break.
- [ ] **Streak + reminders** — daily exercise streak, optional evening "did you do your eyes today?" notification.

---

## Parking Lot — v3+ (re-evaluate later)

These are not killed, just frozen. Pet-system code is intentionally preserved for two reasons: (1) avoid SwiftData migration breakage for v1 users, (2) keep the option open if user research shows pet-style affect matters.

### Frozen — Digital Pet (was v2 Phase 1)

- [ ] **Digital Pet** — pixel-style amber animal, 4-mood emotion system, daily score driven by break compliance. Files preserved: `Models/PetState.swift`, `Features/PetMoodEngine.swift`, `Features/PetNotificationManager.swift`, `Views/PetView.swift`, `Eyescape app/cat-pixel/` GIF assets.
- [ ] **Pet animation states** — Idle/Happy/Tired/Sad/Exercise. Currently coded against the `cat-pixel` GitHub raw URLs.
- [ ] **DI pet avatar** — was rendered in EyescapeWidgetLiveActivity compactLeading/minimal/expanded; replaced with a static `eye.fill` glyph in the same amber.
- [ ] **HomeView pet-centric layout** — replaced with the 3-segment data view above. The original `petSection` is deleted from HomeView; restoring it would require re-adding the `@Environment(PetMoodEngine.self)` + the `showPetBubble` flow.
- [ ] **Pet naming, skin unlocks, mood trend chart** — all Pro upsells from the pet-era plan; archived.

Re-open this section when (a) we have a clear thesis that affect-driven engagement outperforms pure data UX for retention, or (b) we want a kid-targeted variant of Eyescape.

### Frozen — Focus App
**Status**: separate codebase, was tentatively planned as a sister app sharing Eyescape's session loop. No code work this cycle.

---

## Outstanding from v1 (still applies)

| Priority | Item | Where |
|----------|------|-------|
| P1 | StoreKit purchase error UX | `Features/StoreManager.swift`, `Views/PaywallView.swift` |
| P2 | `startActivity()` failure fallback | `Features/SessionManager.swift` |
| Design | a11y label sweep | all Views |
| ✓ Done | Bar-chart label ambiguity | `AnalyticsView.swift` (fixed in this branch) |

---

## Tech notes

| Concern | Choice | Notes |
|---------|--------|-------|
| Pickup tracking | `PickupSession` @Model + scenePhase | Local-only, populated by SessionManager. Real device-wide pickups land in v2.2 via DeviceActivityMonitor. |
| Aggregation | Pure Swift `ScreenTimeAggregator` | No SwiftData / framework deps so it's trivial to test and reuse from the widget. |
| Exercise content | Hard-coded enum `EyeExercise` | Three routines are stable and not user-editable; no need for a database. |
| Family Controls | `AuthorizationCenter.shared.requestAuthorization(for: .individual)` | Self-monitoring mode only, never `.child`. |
| DeviceActivity report | Separate extension target | Apple-mandated sandbox; cross-process via App Group. |
| Schema migration | Add `PickupSession.self` to `sharedModelContainer` schema | New model, no migration needed for existing v1 users. PetState retained for backward compat. |

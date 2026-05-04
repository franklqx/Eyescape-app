# Family Controls Entitlement — Setup & Application Guide

## Why this exists

Eyescape v2 reads system-wide screen-time data via Apple's Family Controls and DeviceActivity APIs to compute the user's daily total, top apps, and pickup behavior. Apple gates these APIs behind an entitlement that must be approved per-app, per-developer.

This doc covers everything we need to do, in order, from "code is ready" to "entitlement approved + extension shipping data on real devices".

## Status snapshot

| Item | Status |
|------|--------|
| `ScreenTimeAuthManager.swift` written | done |
| `DeviceActivityReportExtension/` source files staged | done |
| Family Controls capability enabled on main target | TODO (Xcode UI) |
| Extension target created in project | TODO (Xcode UI) |
| App Group shared between targets | TODO (Xcode UI) |
| Entitlement application submitted to Apple | TODO |
| Entitlement approved | blocked on submission |

## Phase A — Xcode UI work (must do before TestFlight)

Open `Eyescape app/Eyescape app.xcodeproj` in Xcode 16+.

### 1. Family Controls capability on the main app target

1. Select the `Eyescape app` target.
2. **Signing & Capabilities** tab.
3. Click **+ Capability** and add **Family Controls**.
4. This generates `Eyescape app/Eyescape app.entitlements` containing:
   ```xml
   <key>com.apple.developer.family-controls</key>
   <true/>
   ```
5. Verify your Apple Developer team has paid status — free teams cannot use Family Controls.

### 2. Create the Device Activity Report Extension target

1. **File → New → Target**.
2. Pick **Device Activity Report Extension** under iOS → Application Extension.
3. Name it `DeviceActivityReportExtension`. Bundle ID: `<main-bundle>.DeviceActivityReportExtension`.
4. Activate the new scheme when prompted.
5. Xcode generates a stub `<target>.swift` and Info.plist. **Delete those stubs** and instead add the pre-staged files we shipped:
   - `DeviceActivityReportExtension/EyescapeReportExtension.swift`
   - `DeviceActivityReportExtension/DailyActivityReport.swift`
   - `DeviceActivityReportExtension/DailyActivityView.swift`
   - `DeviceActivityReportExtension/Info.plist`

   Right-click the extension group → **Add Files to "Eyescape app"…** → select the four files → ensure **Target Membership** is the extension target.

6. On the extension target, **Signing & Capabilities → + Capability → Family Controls**. Same as step 1, generates an entitlements file.

### 3. App Groups (shared user defaults between app and extension)

Both targets need the same App Group so the main app can read what the extension wrote.

1. Main app → **+ Capability → App Groups** → click **+** → enter `group.com.eyescape.shared`. (Adjust to match your bundle prefix; pick anything that's unique.)
2. Extension target → repeat with the **same** group identifier.
3. In code, share data via:
   ```swift
   let defaults = UserDefaults(suiteName: "group.com.eyescape.shared")!
   ```

### 4. Embed the extension in the main app

1. Main target → **General → Frameworks, Libraries, and Embedded Content**.
2. Confirm `DeviceActivityReportExtension.appex` is listed and set to **Embed Without Signing** (default for extensions).

### 5. Wire the embed into AnalyticsView

After Xcode confirms the extension builds, open `Views/AnalyticsView.swift`. Find the comment block left in Phase 5 and replace it with:

```swift
import DeviceActivity   // add at file top

// inside the body, after aiInsightsSection:
let filter = DeviceActivityFilter(
    segment: .daily(during: DateInterval(
        start: Calendar.current.startOfDay(for: .now),
        end: .now
    )),
    users: .all,
    devices: .init([.iPhone])
)
DeviceActivityReport(.daily, filter: filter)
    .frame(height: 220)
```

## Phase B — Real-device testing (no Apple approval required)

You can test all of the above on your own iPhone with a paid developer account, before submitting the entitlement application.

### Requirements

- iPhone running iOS 17.2 or later (DeviceActivityReport SwiftUI API).
- Apple Developer Program membership ($99 / year). Free personal teams will be blocked at runtime.
- The phone signed in as the Family member you want monitored (for `.individual` mode).

### Test plan

1. Build and run on real device from Xcode.
2. Open Settings tab → **Connect** under Screen Time. The system permission sheet labelled "Eyescape would like to view your activity" should appear. Approve.
3. Use other apps for 5–10 minutes. Lock the device, then re-open Eyescape.
4. AnalyticsView should render the embedded `DailyActivityView` showing total time + top apps.
5. HomeView's `Today` card continues to show the local `PickupSession` figure (lower-bound estimate) — the system data lives in the report extension and reads in a separate process for privacy reasons.

## Phase C — Entitlement application

Reference: <https://developer.apple.com/contact/request/family-controls-distribution>

### When to submit

When the app is feature-complete and you've tested everything in Phase B. Submission to approval typically takes **2–6 weeks** for indie developers — start early. **Account Holder** must submit; submissions from Admin accounts are silently dropped.

### What to submit

For each target separately (main app + every extension), submit one application form. Bundle IDs must match production.

### Suggested application copy

**App description**
> Eyescape is an eye-care app that helps users follow the 20-20-20 rule and reduces digital eye strain by combining a 20-minute work-cycle reminder with daily eye-relaxation exercises.

**How does your app use Family Controls / DeviceActivity?**
> Eyescape reads the user's *own* screen-time data on their own device to surface metrics that motivate healthier viewing habits: today's total screen time, single-pickup duration, and 20-min compliance rate. It also displays a daily Top-Apps panel via a DeviceActivityReport extension. We do not modify the user's app authorization, do not use ManagedSettings, do not implement parental controls, and do not target other accounts. Mode is `.individual` only.

**Privacy / data flow**
> Screen-time aggregates are computed inside the DeviceActivity report extension (sandboxed by Apple). The main app reads only summary tokens via the SwiftUI embed; no app names, durations, or activity tokens are persisted to disk, sent to a server, or shared with third parties. Authorization can be revoked at any time in iOS Settings.

**Audience / age rating**
> 17+. Adults / older teens managing their own digital habits.

**Bundle IDs**
- Main app: `com.<your-team>.eyescape`
- Extension: `com.<your-team>.eyescape.DeviceActivityReportExtension`

### Common rejection reasons (avoid)

- **Submitting before extension exists.** If you only request entitlement for the main app, then add an extension later, you have to reapply for the extension separately. Always submit both at once.
- **Vague justification.** "We need this to display screen time" is too generic. Spell out what data, why, where it stays, and what user benefit it produces.
- **Pretending to be a parental-control app when you aren't.** `.individual` self-monitoring is a valid use case — say so plainly. Don't claim you're for kids if you aren't.
- **App Store metadata mismatch.** Description, screenshots, and privacy policy must reflect the screen-time feature once the entitlement is granted. Have a draft version of all of these ready before submission.

## Risks and contingencies

| Risk | Plan |
|------|------|
| Application stalls past 4 weeks | Open a code-level support request via developer.apple.com; reference the application id. |
| Application denied | Read the response carefully, address each point, resubmit. Most denials are fixable. |
| Apple changes API surface in iOS 18+ | Keep the extension code minimal and Apple-template-shaped so future API changes are easy to follow. |
| User on free Apple developer team tries to test | Surface a clear error in `ScreenTimeAuthManager` — already handled (logs to console). |

## Reference reading

- Apple docs: <https://developer.apple.com/documentation/familycontrols>
- DeviceActivity report: <https://developer.apple.com/documentation/deviceactivity/deviceactivityreport>
- Frederik Riedel "State of the Screen Time API 2024": <https://riedel.wtf/state-of-the-screen-time-api-2024/>
- Julius Brussee guide: <https://medium.com/@juliusbrussee/a-developers-guide-to-apples-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7>

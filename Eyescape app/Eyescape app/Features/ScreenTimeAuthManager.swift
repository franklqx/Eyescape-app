import Foundation
import Observation
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Wraps `FamilyControls.AuthorizationCenter` so the rest of the app can
/// observe the Screen Time authorization status without depending on the
/// framework directly.
///
/// `requestAuthorization()` triggers the system "Family Controls" permission
/// sheet. The capability must be enabled on the app target in Xcode and the
/// `com.apple.developer.family-controls` entitlement granted by Apple before
/// the prompt will succeed in production. In Xcode debug builds with a paid
/// developer team it works without entitlement approval.
@Observable
final class ScreenTimeAuthManager {

    enum Status: String {
        case notDetermined
        case denied
        case approved
    }

    private(set) var status: Status

    init() {
        #if canImport(FamilyControls)
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:      self.status = .approved
        case .denied:        self.status = .denied
        case .notDetermined: self.status = .notDetermined
        @unknown default:    self.status = .notDetermined
        }
        #else
        self.status = .notDetermined
        #endif
    }

    /// Triggers the system permission sheet and updates `status` afterward.
    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("[Eyescape] Family Controls authorization failed: \(error)")
        }
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:      status = .approved
        case .denied:        status = .denied
        case .notDetermined: status = .notDetermined
        @unknown default:    status = .notDetermined
        }
        #endif
    }
}

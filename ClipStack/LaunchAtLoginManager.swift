import Combine
import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the menu UI can toggle launch-at-login.
///
/// `SMAppService.mainApp` (macOS 13+) registers the running app itself as a
/// login item without a helper bundle and without additional entitlements
/// under App Sandbox. The user can also enable/disable it from
/// System Settings → General → Login Items, so we re-read the status on
/// each menu open to stay in sync.
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published private(set) var isEnabled: Bool = false

    private let service = SMAppService.mainApp

    private init() {
        refreshStatus()
    }

    func refreshStatus() {
        isEnabled = service.status == .enabled
    }

    func toggle() {
        do {
            if isEnabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            print("ClipStack: launch-at-login toggle failed: \(error)")
        }
        refreshStatus()
    }
}

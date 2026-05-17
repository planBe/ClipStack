import SwiftUI

@main
struct ClipStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app is a menu-bar-only utility (LSUIElement). We declare a
        // `Settings` scene so SwiftUI's App lifecycle is satisfied without
        // creating a primary window. The status bar item — owned by
        // AppDelegate — is the only user-facing surface.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let clipboardManager = ClipboardManager()
    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = StatusBarController(clipboardManager: clipboardManager)
        self.statusBarController = controller

        // ⌘⇧V opens the menu from anywhere.
        self.hotkeyManager = HotkeyManager { [weak controller] in
            controller?.togglePopover(nil)
        }
    }
}

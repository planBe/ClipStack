import AppKit
import SwiftUI

/// Owns the menu-bar status item and the popover that shows the clipboard menu.
///
/// Replaces SwiftUI's `MenuBarExtra` because we need programmatic control
/// over opening the menu (so the global hotkey can trigger it). The
/// SwiftUI `MenuBarContentView` is hosted inside an `NSHostingController`
/// inside an `NSPopover` — same content, just wrapped in AppKit so we can
/// drive it from outside SwiftUI.
@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let clipboardManager: ClipboardManager

    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()

        // Now that all stored properties are initialized, configure them.
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipStack")
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover.behavior = .transient  // closes when focus leaves
        popover.animates = true

        let rootView = MenuBarContentView()
            .environmentObject(clipboardManager)
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Bring the app to the front so the popover can receive key events.
        NSApp.activate(ignoringOtherApps: true)
    }
}

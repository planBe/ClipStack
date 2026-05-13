import SwiftUI

@main
struct ClipStackApp: App {
    @StateObject private var clipboardManager = ClipboardManager()

    var body: some Scene {
        MenuBarExtra("ClipStack", systemImage: "doc.on.clipboard") {
            MenuBarContentView()
                .environmentObject(clipboardManager)
        }
        .menuBarExtraStyle(.window)
    }
}

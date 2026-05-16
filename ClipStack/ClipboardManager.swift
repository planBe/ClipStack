import AppKit
import Combine
import Foundation

/// Represents a single item in clipboard history.
struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let copiedAt: Date

    init(id: UUID = UUID(), text: String, copiedAt: Date = Date()) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
    }

    /// A short, single-line preview suitable for menu display.
    var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 60 {
            return String(singleLine.prefix(60)) + "…"
        }
        return singleLine
    }
}

/// Watches the system pasteboard and keeps a capped history of recent items.
@MainActor
final class ClipboardManager: ObservableObject {
    @Published private(set) var history: [ClipItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    // Configuration
    let maxItems = 10
    private let pollInterval: TimeInterval = 0.5
    private let storageKey = "ClipStack.history.v1"

    // Self-write prevention is handled by syncing lastChangeCount inside
    // copyToPasteboard — see that method's comment for details.

    init() {
        self.lastChangeCount = pasteboard.changeCount
        loadHistory()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }

    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Respect items marked as concealed (e.g. by password managers).
        // See: https://nspasteboard.org
        let types = pasteboard.types ?? []
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        if types.contains(concealed) {
            return
        }
        let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        if types.contains(transient) {
            return
        }

        guard let string = pasteboard.string(forType: .string),
              !string.isEmpty else {
            return
        }

        addItem(text: string)
    }

    // MARK: - History management

    private func addItem(text: String) {
        // If this exact text is already at the top, do nothing.
        if let first = history.first, first.text == text {
            return
        }

        // Remove any existing duplicate so we can move it to the top.
        history.removeAll { $0.text == text }

        history.insert(ClipItem(text: text), at: 0)

        // Cap the history.
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }

        saveHistory()
    }

    /// Writes the given item's text back to the pasteboard so the user can paste it.
    func copyToPasteboard(_ item: ClipItem) {
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        // Sync lastChangeCount to the post-write value so the next poll's
        // changeCount comparison short-circuits and we don't re-capture our
        // own write as a new history item.
        lastChangeCount = pasteboard.changeCount

        // Move this item to the top of history without creating a duplicate.
        history.removeAll { $0.id == item.id }
        history.insert(item, at: 0)
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func remove(_ item: ClipItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    // MARK: - Persistence

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Non-fatal; history will just not persist this session.
            print("ClipStack: failed to save history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            history = try JSONDecoder().decode([ClipItem].self, from: data)
        } catch {
            print("ClipStack: failed to load history: \(error)")
        }
    }
}

import AppKit
import Combine
import Foundation

/// What a single clipboard history item actually holds.
///
/// - text: a plain string
/// - image: PNG data persisted to the sandbox's Application Support cache;
///   the associated value is the filename, not the data itself
/// - file: a file the user copied in Finder; we store the path + the
///   display name so we can paste both a file URL (for Finder targets)
///   and a fallback filename string (for text-only targets)
enum ClipContent: Codable, Equatable {
    case text(String)
    case image(filename: String)
    case file(path: String, name: String)
}

/// Represents a single item in clipboard history.
struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: ClipContent
    let copiedAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), content: ClipContent, copiedAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.copiedAt = copiedAt
        self.isPinned = isPinned
    }

    // Custom decoder so v0.3-persisted items (no isPinned field) decode
    // cleanly with isPinned = false. Avoids bumping the storage key again.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(ClipContent.self, forKey: .content)
        copiedAt = try container.decode(Date.self, forKey: .copiedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

/// Watches the system pasteboard and keeps a capped history of recent items.
@MainActor
final class ClipboardManager: ObservableObject {
    @Published private(set) var history: [ClipItem] = []
    @Published private(set) var maxItems: Int = 10

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    // Configuration
    let minMaxItems = 5
    let maxMaxItems = 50
    private let pollInterval: TimeInterval = 0.5
    private let storageKey = "ClipStack.history.v2"
    private let legacyStorageKey = "ClipStack.history.v1"
    private let maxItemsKey = "ClipStack.maxItems.v1"
    private let maxImageBytes: Int = 5 * 1024 * 1024  // 5 MB cap per image

    // Self-write prevention is handled by syncing lastChangeCount inside
    // copyToPasteboard — see that method's comment for details.

    init() {
        self.lastChangeCount = pasteboard.changeCount
        loadMaxItems()
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
        if types.contains(concealed) { return }
        let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        if types.contains(transient) { return }

        // Priority order: file > image > text. File URL is most specific
        // (user copied a file in Finder). Image second (screenshot, drag
        // from a browser). Text last (the fallback for everything else).

        if let fileURL = readFileURL() {
            addFile(url: fileURL)
            return
        }

        if let imageData = readImageData() {
            addImage(data: imageData)
            return
        }

        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            addText(text: string)
            return
        }
    }

    private func readFileURL() -> URL? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return nil
        }
        // Only treat real on-disk file URLs as files. Web URLs land in text.
        return urls.first(where: { $0.isFileURL })
    }

    private func readImageData() -> Data? {
        if let png = pasteboard.data(forType: .png) {
            return png
        }
        if let tiff = pasteboard.data(forType: .tiff) {
            // Convert TIFF to PNG so storage and round-trip are consistent.
            if let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                return png
            }
            return tiff
        }
        return nil
    }

    // MARK: - History management

    private func addText(text: String) {
        // If this exact text is at the top of unpinned, do nothing.
        let pinnedCount = pinnedSectionCount()
        if pinnedCount < history.count,
           case .text(let s) = history[pinnedCount].content, s == text {
            return
        }

        // Find existing duplicate and move it (preserving pin state).
        if let idx = history.firstIndex(where: { item in
            if case .text(let s) = item.content { return s == text }
            return false
        }) {
            let existing = history.remove(at: idx)
            insertAtTopOfSection(existing)
            saveHistory()
            return
        }

        insertNewItem(ClipItem(content: .text(text)))
    }

    private func addImage(data: Data) {
        guard data.count <= maxImageBytes else { return }
        guard let filename = saveImageToCache(data) else { return }
        insertNewItem(ClipItem(content: .image(filename: filename)))
    }

    private func addFile(url: URL) {
        let path = url.path
        let name = url.lastPathComponent

        // Dedup on path (preserving pin state if duplicate exists).
        if let idx = history.firstIndex(where: { item in
            if case .file(let p, _) = item.content { return p == path }
            return false
        }) {
            let existing = history.remove(at: idx)
            insertAtTopOfSection(existing)
            saveHistory()
            return
        }

        insertNewItem(ClipItem(content: .file(path: path, name: name)))
    }

    private func insertNewItem(_ item: ClipItem) {
        // New items are unpinned; they go to the top of the unpinned section.
        insertAtTopOfSection(item)
        evictExcess()
        saveHistory()
    }

    private func insertAtTopOfSection(_ item: ClipItem) {
        if item.isPinned {
            history.insert(item, at: 0)
        } else {
            history.insert(item, at: pinnedSectionCount())
        }
    }

    private func pinnedSectionCount() -> Int {
        history.prefix(while: { $0.isPinned }).count
    }

    private func evictExcess() {
        var unpinnedCount = history.filter { !$0.isPinned }.count
        var i = history.count - 1
        while unpinnedCount > maxItems && i >= 0 {
            if !history[i].isPinned {
                let evicted = history.remove(at: i)
                deleteContent(of: evicted)
                unpinnedCount -= 1
            }
            i -= 1
        }
    }

    /// Writes the given item's content back to the pasteboard so the user can paste it.
    func copyToPasteboard(_ item: ClipItem) {
        pasteboard.clearContents()

        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)

        case .image(let filename):
            if let data = loadImageData(filename: filename) {
                pasteboard.setData(data, forType: .png)
                if let nsImage = NSImage(data: data),
                   let tiff = nsImage.tiffRepresentation {
                    pasteboard.setData(tiff, forType: .tiff)
                }
            }

        case .file(let path, let name):
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                pasteboard.writeObjects([url as NSURL])
            }
            pasteboard.setString(name, forType: .string)
        }

        // Sync lastChangeCount to the post-write value so the next poll's
        // changeCount comparison short-circuits and we don't re-capture our
        // own write as a new history item.
        lastChangeCount = pasteboard.changeCount

        // Move this item to the top of its section without creating a duplicate.
        history.removeAll { $0.id == item.id }
        insertAtTopOfSection(item)
        saveHistory()
    }

    func clearHistory() {
        // Clear only unpinned items — pinned stay.
        let toEvict = history.filter { !$0.isPinned }
        history.removeAll { !$0.isPinned }
        for item in toEvict {
            deleteContent(of: item)
        }
        saveHistory()
    }

    func remove(_ item: ClipItem) {
        history.removeAll { $0.id == item.id }
        deleteContent(of: item)
        saveHistory()
    }

    func togglePin(_ item: ClipItem) {
        guard let idx = history.firstIndex(where: { $0.id == item.id }) else { return }
        history[idx].isPinned.toggle()

        let updated = history[idx]
        history.remove(at: idx)
        insertAtTopOfSection(updated)

        // Unpinning could push the unpinned section over the cap.
        evictExcess()
        saveHistory()
    }

    func setMaxItems(_ newValue: Int) {
        let clamped = min(max(newValue, minMaxItems), maxMaxItems)
        guard clamped != maxItems else { return }
        maxItems = clamped
        UserDefaults.standard.set(clamped, forKey: maxItemsKey)
        evictExcess()
        saveHistory()
    }

    // MARK: - Image cache (on-disk storage for image content)

    /// Reads PNG data for an image item from the sandbox cache.
    /// Public so the menu UI can render thumbnails.
    func loadImageData(filename: String) -> Data? {
        let url = imageCacheDirectory().appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    private func saveImageToCache(_ data: Data) -> String? {
        let filename = "\(UUID().uuidString).png"
        let url = imageCacheDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            print("ClipStack: failed to save image: \(error)")
            return nil
        }
    }

    private func deleteContent(of item: ClipItem) {
        guard case .image(let filename) = item.content else { return }
        let url = imageCacheDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    private func imageCacheDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("ClipStack/cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Persistence

    private func loadMaxItems() {
        if let stored = UserDefaults.standard.object(forKey: maxItemsKey) as? Int {
            maxItems = min(max(stored, minMaxItems), maxMaxItems)
        }
    }

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
        // 1. Try the v2 (current) format first.
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                history = try JSONDecoder().decode([ClipItem].self, from: data)
                // Defensive: re-sort so pinned items lead, in case data got out of order.
                normalizeOrder()
                return
            } catch {
                print("ClipStack: failed to load v2 history: \(error)")
            }
        }

        // 2. Fall back to v1 (legacy text-only) and migrate.
        if let legacyData = UserDefaults.standard.data(forKey: legacyStorageKey) {
            migrateLegacyHistory(legacyData)
        }
    }

    private func normalizeOrder() {
        let pinned = history.filter { $0.isPinned }
        let unpinned = history.filter { !$0.isPinned }
        history = pinned + unpinned
    }

    private func migrateLegacyHistory(_ data: Data) {
        struct LegacyClipItem: Codable {
            let id: UUID
            let text: String
            let copiedAt: Date
        }

        do {
            let legacy = try JSONDecoder().decode([LegacyClipItem].self, from: data)
            history = legacy.map { old in
                ClipItem(id: old.id, content: .text(old.text), copiedAt: old.copiedAt)
            }
            saveHistory()
        } catch {
            print("ClipStack: failed to migrate v1 history: \(error)")
        }
    }
}

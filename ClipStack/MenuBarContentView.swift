import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.openURL) private var openURL
    @StateObject private var launchAtLogin = LaunchAtLoginManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if clipboardManager.history.isEmpty {
                emptyState
            } else {
                historyList
            }

            Divider()

            settings

            Divider()

            footer
        }
        .frame(width: 360)
        .onAppear {
            launchAtLogin.refreshStatus()
        }
    }

    private var header: some View {
        HStack {
            Text("Clipboard History")
                .font(.headline)
            Spacer()
            Text("\(clipboardManager.history.count)/\(clipboardManager.maxItems)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No items yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Copy something to get started.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(clipboardManager.history.enumerated()), id: \.element.id) { index, item in
                    HistoryRow(item: item, index: index)
                    if index < clipboardManager.history.count - 1 {
                        Divider().padding(.leading, 36)
                    }
                }
            }
        }
        .frame(minHeight: 340, maxHeight: 400)
    }

    private var settings: some View {
        Toggle(isOn: Binding(
            get: { launchAtLogin.isEnabled },
            set: { _ in launchAtLogin.toggle() }
        )) {
            Text("Launch at Login")
                .font(.caption)
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack {
            Button {
                clipboardManager.clearHistory()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(clipboardManager.history.isEmpty)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct HistoryRow: View {
    let item: ClipItem
    let index: Int

    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovering = false

    var body: some View {
        Button {
            clipboardManager.copyToPasteboard(item)
        } label: {
            HStack(spacing: 8) {
                // Number badge (1-9, then 0 for the 10th).
                Text(shortcutLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .center)

                contentView

                if isHovering {
                    Button {
                        clipboardManager.remove(item)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(isHovering ? Color.accentColor.opacity(0.15) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var contentView: some View {
        switch item.content {
        case .text(let string):
            Text(HistoryRow.textPreview(string))
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .image(let filename):
            HStack(spacing: 8) {
                imageThumbnail(filename: filename)
                Text("Image")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .file(let path, let name):
            HStack(spacing: 8) {
                fileIcon(path: path)
                Text(name)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func fileIcon(path: String) -> some View {
        if HistoryRow.isImageFile(path: path),
           let nsImage = NSImage(contentsOf: URL(fileURLWithPath: path)) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .cornerRadius(2)
        } else {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        }
    }

    private static func isImageFile(path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "heic", "webp"].contains(ext)
    }

    @ViewBuilder
    private func imageThumbnail(filename: String) -> some View {
        if let data = clipboardManager.loadImageData(filename: filename),
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .cornerRadius(2)
        } else {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
        }
    }

    private static func textPreview(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 60 {
            return String(singleLine.prefix(60)) + "…"
        }
        return singleLine
    }

    private var shortcutLabel: String {
        // 1...9, then 0 for the 10th
        if index < 9 { return "\(index + 1)" }
        if index == 9 { return "0" }
        return "·"
    }
}

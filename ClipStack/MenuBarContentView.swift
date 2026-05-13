import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.openURL) private var openURL

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

            footer
        }
        .frame(width: 360)
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
        .frame(maxHeight: 400)
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

                Text(item.preview)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

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

    private var shortcutLabel: String {
        // 1...9, then 0 for the 10th
        if index < 9 { return "\(index + 1)" }
        if index == 9 { return "0" }
        return "·"
    }
}

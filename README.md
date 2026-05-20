# ClipStack

A free, open-source clipboard history app for macOS. Lives in your menu bar and remembers the last 10 things you copied.

## Status

🚧 **v0.7 — early development, feature-complete for the v0.x roadmap.** Core clipboard monitoring, menu bar UI, launch-at-login, image + file support, favorites, configurable history size, global hotkey (⌃⌘V), search, and image-file-as-image round-trip are all in place. Notarized release is the remaining roadmap item (blocked on the Apple Developer display-name change landing).

## Features

- 📋 Keeps the last N items you copied — text, images, or files (default 10, configurable 5–50)
- 🔍 Search within history — auto-focuses when the menu opens; ⌃⌘V → type-to-filter
- ⌨️ Global hotkey **⌃⌘V** opens the menu from any app — fully keyboard-driven workflow
- 📌 Pin items as favorites — pinned items never get evicted, even when the cap is exceeded
- 🖼️ Image previews and file thumbnails in the menu
- 🍎 Lives quietly in the menu bar (no dock icon)
- 💾 History persists across launches; image data cached in the app sandbox container
- 🚀 Launch at login (toggle from the menu)
- 🔒 Respects `org.nspasteboard.ConcealedType` (won't capture passwords from password managers that mark them)
- 🆓 Free and open-source forever (MIT licensed)
- 🪶 Tiny: no dependencies, pure SwiftUI + AppKit

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build from source)

## Building from source

1. Open `ClipStack.xcodeproj` in Xcode.
2. Select the `ClipStack` scheme.
3. ⌘R to build and run.

The app will appear as a clipboard icon in your menu bar.

## How it works

ClipStack polls `NSPasteboard.general.changeCount` every 500ms. When the change count increments, it inspects the pasteboard in this priority order: **file URL → image data → text string**. Whatever wins becomes the new history item.

- **Text** is stored as a plain string in `UserDefaults` under the key `ClipStack.history.v2`.
- **Images** are stored as PNG data inside the app sandbox container at `<container>/Library/Application Support/ClipStack/cache/<UUID>.png`. Items capped at 5 MB each; the cache file is deleted when the item is evicted or cleared.
- **Files** keep the original on-disk path plus the display name. Image files automatically render a real thumbnail in the menu instead of the generic type icon.

Clicking an item in the menu writes it back to the pasteboard. Text writes a string; images write PNG + TIFF; files write both the file URL (for Finder and image-aware targets) and the filename as a string fallback.

Launch-at-login is implemented with `SMAppService.mainApp` (macOS 13+) — no helper bundle, no additional entitlements under App Sandbox. The toggle state is also reflected by System Settings → General → Login Items, so changes you make there are picked up the next time you open the ClipStack menu.

The global hotkey (⌃⌘V) is registered via Carbon's `RegisterEventHotKey` — long deprecated but still the only public API that registers a system-wide hotkey without Accessibility permission, which keeps ClipStack sandbox-clean and friction-free for users. ⌃⌘V was chosen over the obvious-but-conflicty ⌘⇧V (used by VS Code, Pages, and other apps for various paste/preview commands). Configurable hotkey is on the roadmap. The menu bar item is a manual `NSStatusItem` + `NSPopover` (not SwiftUI's `MenuBarExtra`) so the hotkey handler can programmatically open the popover.

## Roadmap

- [x] Launch at login (via `SMAppService.mainApp`) — shipped in v0.2
- [x] Support for images and files, not just text — shipped in v0.3
- [x] Configurable history size — shipped in v0.4
- [x] Favorites that don't get evicted — shipped in v0.4
- [x] Global hotkey (⌃⌘V) to open the menu without the mouse — shipped in v0.5 (default changed from ⌘⇧V to ⌃⌘V in 2026-05-17 to avoid VS Code's Markdown Preview shortcut)
- [x] Search within history — shipped in v0.6
- [x] When an image-file is copied, write both image data and file URL on round-trip — shipped in v0.7
- [ ] Notarized release build distributed via GitHub Releases and Homebrew Cask (blocked on the Apple Developer display-name change)

## Privacy

ClipStack collects no data. Everything runs on your Mac; nothing is sent anywhere. See [PRIVACY.md](PRIVACY.md) for the full policy.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome. The codebase is intentionally tiny — around 720 lines of Swift across six files — so it should be easy to dive in.

## About

Part of the **Stack** family of free, open-source macOS utilities. See also:

- [TimeStack](https://github.com/planBe/TimeStack) — always-on-top transparent overlay timers

Made by Michael Wild – plan Be creative.

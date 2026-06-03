# ClipStack

A free, open-source clipboard history app for macOS. Lives in your menu bar and remembers the last N things you copied — text, images, or files.

## Status

**v1.0 shipped.** Live on GitHub Releases as a notarized direct download since 2026-05-21; submitted to the Mac App Store the same day, awaiting Apple review. The v0.x roadmap is feature-complete and shipped as v1.0.

## Features

- 📋 Keeps the last N items you copied — text, images, or files (default 10, configurable 5–50)
- 🔍 Search within history — auto-focuses when the menu opens; ⌥⇧⌘P → type-to-filter
- ⌨️ Global hotkey **⌥⇧⌘P** opens the menu from any app — fully keyboard-driven workflow (configurable hotkey queued for v1.1)
- 📌 Pin items as favorites — pinned items never get evicted, even when the cap is exceeded
- 🖼️ Image previews and file thumbnails in the menu
- 🔄 Image files round-trip as image data — paste an image file from Finder into Pages/Mail/Safari and the image embeds inline
- 🍎 Lives quietly in the menu bar (no dock icon)
- 💾 History persists across launches; image data cached in the app sandbox container
- 🚀 Launch at login (toggle from the menu)
- 🔒 Respects `org.nspasteboard.ConcealedType` (won't capture passwords from password managers that mark them)
- 🆓 Free and open-source forever (MIT licensed)
- 🪶 Tiny: no dependencies, pure SwiftUI + AppKit

## Install

**From GitHub Releases** (live now): https://github.com/planBe/ClipStack/releases/tag/v1.0

1. Download `ClipStack-v1.0.zip`
2. Unzip and drag `ClipStack.app` to your Applications folder
3. On first launch, right-click the app and pick "Open" (macOS Gatekeeper one-time confirmation for non-App-Store apps — the app is fully notarized so you'll only see this prompt once)
4. ClipStack appears as a clipboard icon in your menu bar

**From the Mac App Store** (post-approval): apps.apple.com/app/id6769932490 — link will go live when Apple completes review.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel (universal binary)
- Xcode 16 or later to build from source

## Building from source

1. Clone the repo.
2. Open `ClipStack.xcodeproj` in Xcode.
3. ⌘R to build and run.

The app will appear as a clipboard icon in your menu bar.

## How it works

ClipStack polls `NSPasteboard.general.changeCount` every 500ms. When the change count increments, it inspects the pasteboard in this priority order: **file URL → image data → text string**. Whatever wins becomes the new history item.

- **Text** is stored as a plain string in `UserDefaults` under the key `ClipStack.history.v2`.
- **Images** are stored as PNG data inside the app sandbox container at `<container>/Library/Application Support/ClipStack/cache/<UUID>.png`. Items capped at 5 MB each; the cache file is deleted when the item is evicted or cleared.
- **Files** keep the original on-disk path plus the display name. Image files automatically render a real thumbnail in the menu instead of the generic type icon.

Clicking an item in the menu writes it back to the pasteboard. Text writes a string; images write PNG + TIFF; files write both the file URL (for Finder and image-aware targets) and the filename as a string fallback. Image files also write image bytes alongside the file URL so pasting into rich-content apps embeds the image inline.

Launch-at-login is implemented with `SMAppService.mainApp` (macOS 13+) — no helper bundle, no additional entitlements under App Sandbox. The toggle state is also reflected by System Settings → General → Login Items, so changes you make there are picked up the next time you open the ClipStack menu.

The global hotkey (⌥⇧⌘P, P for Paste) is registered via Carbon's `RegisterEventHotKey` — long deprecated but still the only public API that registers a system-wide hotkey without Accessibility permission, which keeps ClipStack sandbox-clean and friction-free. The chord was retuned across pre-release to dodge real-world conflicts: ⌘⇧V (VS Code's Markdown Preview, many editors' Paste Without Formatting), then ⌃⌘V (Terminal and other apps), then ⌥⇧⌘V — which turned out to be the system-wide "Paste and Match Style" chord (TextEdit/Pages/Mail and many others), so a *global* hotkey on it would intercept Paste-and-Match-Style for every user. The v1.0.1 default ⌥⇧⌘P is not bound to any system-standard action, and the full ⌥⇧⌘ modifier keeps it clear of plain ⌘V copy/paste. Configurable hotkey is queued for v1.1. The menu bar item is a manual `NSStatusItem` + `NSPopover` (not SwiftUI's `MenuBarExtra`) so the hotkey handler can programmatically open the popover.

## Roadmap

- [x] v0.2 — Launch at login (via `SMAppService.mainApp`)
- [x] v0.3 — Support for images and files, not just text
- [x] v0.4 — Configurable history size + favorites that don't get evicted
- [x] v0.5 — Global hotkey to open the menu without the mouse (default chord retuned twice pre-1.0 to dodge real-world conflicts)
- [x] v0.6 — Search within history
- [x] v0.7 — When an image-file is copied, write both image data and file URL on round-trip
- [x] v1.0 — Notarized GitHub Release + submitted to Mac App Store (2026-05-21)
- [x] v1.0.1 — Global hotkey default changed ⌥⇧⌘V → ⌥⇧⌘P (⌥⇧⌘V collided with the system "Paste and Match Style" chord)
- [ ] v1.1 — Configurable global hotkey (so users can pick their own chord instead of the hard-coded ⌥⇧⌘P default)

## Privacy

ClipStack collects no data. Everything runs on your Mac; nothing is sent anywhere. See [PRIVACY.md](PRIVACY.md) for the full policy.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome. The codebase is intentionally tiny — around 1000 lines of Swift across six files — so it should be easy to dive in.

## About

Part of the **Stack** family of free, open-source macOS utilities. See also:

- [TimeStack](https://github.com/planBe/TimeStack) — always-on-top transparent overlay timers (v1.1 live on GitHub Releases; v1.0 in Mac App Store review)

Made by Michael Wild – plan Be creative.

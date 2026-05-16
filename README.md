# ClipStack

A free, open-source clipboard history app for macOS. Lives in your menu bar and remembers the last 10 things you copied.

## Status

🚧 **v0.2 — early development.** Core clipboard monitoring, menu bar UI, and launch-at-login are in place. Global hotkey and richer content types are on the roadmap.

## Features

- 📋 Keeps the last 10 text items you copied or cut
- 🍎 Lives quietly in the menu bar (no dock icon)
- 💾 History persists across launches
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

ClipStack polls `NSPasteboard.general.changeCount` every 500ms. When the change count increments, it reads the new clipboard contents, deduplicates against existing history, prepends the new item, and trims the list to 10 entries. History is persisted to `UserDefaults` as JSON.

Clicking an item in the menu writes it back to the pasteboard so you can paste it normally with ⌘V.

Launch-at-login is implemented with `SMAppService.mainApp` (macOS 13+) — no helper bundle, no additional entitlements under App Sandbox. The toggle state is also reflected by System Settings → General → Login Items, so changes you make there are picked up the next time you open the ClipStack menu.

## Roadmap

- [x] Launch at login (via `SMAppService.mainApp`) — shipped in v0.2
- [ ] Global hotkey (⌘⇧V) to open the menu without the mouse
- [ ] Support for images and files, not just text
- [ ] Configurable history size (currently fixed at 10)
- [ ] Search within history
- [ ] Optional "favorites" that don't get evicted
- [ ] Notarized release build distributed via GitHub Releases and Homebrew Cask

## Privacy

ClipStack collects no data. Everything runs on your Mac; nothing is sent anywhere. See [PRIVACY.md](PRIVACY.md) for the full policy.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome. The codebase is intentionally tiny — three Swift files — so it should be easy to dive in.

## About

Part of the **Stack** family of free, open-source macOS utilities. See also:

- [TimeStack](https://github.com/planBe/TimeStack) — always-on-top transparent overlay timers

Made by Michael Wild – plan Be creative.

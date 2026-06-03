# ClipStack Privacy Policy

**Last updated:** 2026-05-26

## Summary

**ClipStack collects no data.** It runs entirely on your Mac. Nothing is sent to any server. No analytics, no telemetry, no third parties.

## What ClipStack does with your clipboard

ClipStack reads the contents of the macOS clipboard (`NSPasteboard.general`) so it can keep a short history of what you copy — text, images, or files. The history holds the last N items (configurable 5–50, default 10). Items you pin as favorites stay in the history regardless of the cap. Everything is stored locally on your Mac:

- **Text** is stored in your user account's preferences (`UserDefaults`).
- **Images** are stored as PNG data inside the ClipStack app's private sandbox container (`<container>/Library/Application Support/ClipStack/cache/`). Items are capped at 5 MB each and the cache file is deleted when the item is evicted or cleared.
- **Files** keep the original on-disk path plus the display name — the file itself stays where it is; ClipStack only remembers where to find it.

The history never leaves your device.

ClipStack respects the `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType` pasteboard markers. When a password manager (1Password, Bitwarden, Keychain Access, etc.) marks a copied item as concealed or transient, ClipStack does not capture it. Your passwords stay out of the history.

When you click an image file from the history to paste it, ClipStack reads the file's bytes (so it can write both the file URL AND the image data to the pasteboard — letting you paste images inline into Mail, Pages, Safari rich-text fields, etc.). This read happens only at your explicit click; ClipStack does not scan files in the background.

You can clear ClipStack's history at any time from the menu bar item.

## Data ClipStack does NOT collect

- Personal information (name, email, address, phone)
- Device identifiers (IDFA, UUID, hardware serial)
- Location
- Health, financial, browsing, or search data
- Crash reports or diagnostics
- Anything sent over the network — ClipStack makes no network calls

## Third parties

ClipStack uses no third-party SDKs, no analytics services, no advertising networks, no crash reporters. The full source code is published at https://github.com/planBe/ClipStack so you can verify this yourself.

## App Sandbox

ClipStack runs inside Apple's App Sandbox with **no network entitlements** and **no file-system entitlements beyond its own private container**. It can:

- Read and write the macOS clipboard
- Store data in its own sandbox container (where the image cache and preferences live)
- Read user-pasted file contents (when you click an image-file item from history, as described above)

The global hotkey (⌥⇧⌘P) is registered via Carbon's `RegisterEventHotKey` API, which is sandbox-clean and does **not** require macOS Accessibility permission — ClipStack will never prompt you to grant accessibility access.

## Children's privacy

ClipStack is not directed at children under 13. Because ClipStack collects no data at all, no child-specific protections beyond those above are necessary.

## Changes to this policy

If ClipStack ever changes its data practices, this file will be updated and the "Last updated" date above will change. Past versions of this policy are available in the git history at https://github.com/planBe/ClipStack/commits/main/PRIVACY.md.

## Contact

Questions about this policy or about ClipStack itself: open an issue at https://github.com/planBe/ClipStack/issues or email **michael@planbecreative.com**.

---

Made by Michael Wild – plan Be creative.

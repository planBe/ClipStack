# ClipStack Privacy Policy

**Last updated:** 2026-05-15

## Summary

**ClipStack collects no data.** It runs entirely on your Mac. Nothing is sent to any server. No analytics, no telemetry, no third parties.

## What ClipStack does with your clipboard

ClipStack reads the contents of the macOS clipboard (`NSPasteboard.general`) so it can keep a short history of the last 10 text items you copy. This history is stored locally on your Mac in your user account's preferences (`UserDefaults`). It never leaves your device.

ClipStack respects the `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType` pasteboard markers. When a password manager (1Password, Bitwarden, Keychain Access, etc.) marks a copied item as concealed or transient, ClipStack does not capture it. Your passwords stay out of the history.

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

ClipStack runs inside Apple's App Sandbox with no network entitlements and no file-system entitlements beyond what's required for the system to function. It can only access the clipboard and its own private container.

## Children's privacy

ClipStack is not directed at children under 13. Because ClipStack collects no data at all, no child-specific protections beyond those above are necessary.

## Changes to this policy

If ClipStack ever changes its data practices, this file will be updated and the "Last updated" date above will change. Past versions of this policy are available in the git history at https://github.com/planBe/ClipStack/commits/main/PRIVACY.md.

## Contact

Questions about this policy or about ClipStack itself: open an issue at https://github.com/planBe/ClipStack/issues or email **michael@planbecreative.com**.

---

Made by Michael Wild – plan Be creative.

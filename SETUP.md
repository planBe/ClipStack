# Xcode Setup Guide

The four Swift/plist files in `ClipStack/` are the entire app. Here's how to get them into an Xcode project that builds.

## Step 1: Create a new Xcode project

1. Open Xcode → **File → New → Project…**
2. Choose **macOS → App** → Next
3. Fill in:
   - **Product Name:** `ClipStack`
   - **Team:** Your Apple ID (or "None" for local dev — see "Distribution" in README)
   - **Organization Identifier:** `com.planbecreative` (so the bundle ID becomes `com.planbecreative.ClipStack`)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
   - **Include Tests:** unchecked (optional)
4. Save it somewhere convenient.

Xcode generates a default project with a `ClipStackApp.swift` and `ContentView.swift`.

## Step 2: Replace the generated files

1. In Xcode's file navigator, **delete** the default `ClipStackApp.swift` and `ContentView.swift` (choose "Move to Trash").
2. Drag these files from this repo into the `ClipStack` group in Xcode:
   - `ClipStackApp.swift`
   - `ClipboardManager.swift`
   - `MenuBarContentView.swift`
3. When prompted, check **"Copy items if needed"** and make sure the `ClipStack` target is selected.

## Step 3: Configure the target

In the project settings (click the blue project icon at the top of the file navigator):

1. Select the **ClipStack** target → **General** tab:
   - **Minimum Deployments:** macOS **13.0**
   - **App Category:** Utilities (optional)

2. **Info** tab — add these keys to the Info.plist:
   - **Application is agent (UIElement)** = `YES` *(this hides the dock icon — critical for a menu bar app)*
   - **Bundle version** = `1`
   - **Bundle version string, short** = `0.1.0`

   Alternatively, copy the contents of the `Info.plist` file in this repo into Xcode's generated Info.plist.

3. **Signing & Capabilities** tab:
   - For local testing, "Sign to Run Locally" is fine.
   - The default App Sandbox capability is okay — clipboard access doesn't need any special entitlements.

## Step 4: Build and run

⌘R. The clipboard icon should appear in your menu bar. Copy some text from anywhere and click the icon — you'll see it in the history.

## If something goes wrong

- **No menu bar icon appears:** Check that `LSUIElement` (Application is agent) is set to `YES` in Info.plist. Without it, the app launches but the menu bar item gets fought over by the dock app.
- **History doesn't persist:** Check Console.app for messages prefixed with "ClipStack:" — there may be a sandbox/UserDefaults issue.
- **App captures passwords from 1Password/Bitwarden:** It shouldn't — those apps mark their pasteboard items with `org.nspasteboard.ConcealedType`, which ClipStack respects. If they're getting captured anyway, the password manager isn't setting the flag; file an issue with them.

# NotchMate

**Quick actions, tucked into your MacBook’s notch.**

NotchMate is a lightweight macOS utility that reveals a compact action panel when you move your pointer over the top-center notch area. It stays in the menu bar, runs in the background, and can launch when you sign in.

## Features

- **Screenshot:** choose a screen region with macOS’s built-in screenshot selector. Captures are saved to your Desktop.
- **Timer:** start or pause a 15-minute countdown.
- **Quick note:** keep a small note handy for the current app session.
- **Notch-aware design:** a flat, top-aligned panel expands on hover and keeps the controls close to the notch.
- **Background launch:** registers with macOS Login Items the first time the app runs.

## Install

Download the latest **NotchMate macOS arm64** archive from [GitHub Releases](https://github.com/mhmdbilal1/notchmate/releases/latest), unzip it, and move `NotchMate.app` into `/Applications`. Open the app once to enable its Login Item. You can review startup behavior in **System Settings → General → Login Items**.

The app is currently distributed as an ad hoc signed prototype and is not notarized. If macOS blocks the first launch, Control-click the app in Finder and choose **Open**.

## Build from source

### Requirements

- macOS 14 or later
- Xcode Command Line Tools
- Apple silicon Mac (arm64)

Run the build script from the repository root:

```sh
./scripts/build.sh
```

This creates `build/NotchMate.app` and `dist/NotchMate-macOS-arm64.zip`. Open the app from `build` or copy it to `/Applications`.

## Use

- Move the pointer over the top-center panel to reveal the controls.
- Select the camera icon to choose a screenshot region.
- Select the timer icon to start or pause the 15-minute countdown.
- Select the note icon to show or hide the session note field.
- Use the NotchMate menu bar icon to reopen or quit the app.

Screenshot capture uses Apple’s system `screencapture` utility and follows macOS privacy settings. Notes are kept in memory and are cleared when the app quits.

## Project layout

```text
NotchMate/
  NotchMate.swift       SwiftUI interface and AppKit app lifecycle
scripts/
  build.sh              Builds and packages the macOS app
```

## License

No license file is included yet, so this project is not currently offered under an open-source license.

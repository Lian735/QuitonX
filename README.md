# QuitonX

QuitonX is a macOS menu-bar companion that watches for apps with no open windows and quits them automatically. It uses Accessibility APIs to observe window events, then terminates windowless apps after a short confirmation delay, keeping your desktop tidy and your Dock clean.

⚠️ Note: QuitonX skips certain system apps (like Finder and System Settings) and won’t terminate itself.

## Highlights

- Menu-bar toggle to enable/disable QuitonX at any time.
- Automatically quits apps once they have no open windows.
- Optional protection against quitting the current frontmost app.
- Adjustable confirmation delay before termination.
- Launch at login and optional notifications for performed actions.

## Requirements

- macOS with Accessibility permissions enabled for QuitonX.
- Notification permission if you want action notifications.

## Installation

If you have a released build:

1. Download the latest release artifact (e.g., a `.dmg`).
2. Drag **QuitonX** into the **Applications** folder.
3. Open **QuitonX** from Applications.
4. If macOS blocks the app, go to **System Settings → Privacy & Security** and choose **Open Anyway**.

If you’re building from source:

1. Open `QuitonX.xcodeproj` in Xcode.
2. Build and run the **QuitonX** target.

## First‑Run Setup

1. Launch QuitonX from Applications (or Xcode).
2. Grant **Accessibility** permission when prompted so it can observe window events.
3. (Optional) Grant **Notifications** permission if you want alerts.
4. Use the menu‑bar popover to toggle QuitonX on or off.

## Settings

Open **Settings** from the menu‑bar popover to configure:

- **Allow quitting frontmost app**: protect the current active app from being quit.
- **Launch at login**: start QuitonX automatically when you sign in.
- **Confirmation delay**: control how long QuitonX waits before quitting a windowless app.
- **Show notifications**: receive notifications when actions occur.

## Tips & Troubleshooting

- If nothing happens, confirm **Accessibility** permission is enabled in **System Settings → Privacy & Security**.
- If apps close too quickly or too slowly, adjust **Confirmation delay**.
- Some apps are not yet supported; QuitonX may skip them until compatibility improves.

# QuitonX

QuitonX is a lightweight macOS menu-bar companion that automatically quits windowless apps after you close their last window. It listens to accessibility window events, waits for a configurable confirmation delay, and then terminates apps with zero windows to keep your Dock and ⌘-Tab list tidy.

> ⚠️ Note: QuitonX is designed for desktop organization and decluttering. Some apps don’t respond well to automatic termination yet—use the toggle to disable it when needed.

## Highlights

- **Auto-quit windowless apps** so lingering processes don’t hang around after you close the last window.
- **Menu bar toggle** to enable/disable QuitonX instantly.
- **Configurable safety controls**: confirmation delay and “allow quitting frontmost app”.
- **Notifications** when actions are performed (optional).
- **Launch at login** so it’s always ready.

## Requirements

- macOS (Apple Silicon or Intel)
- Accessibility permission so the app can observe window events
- Notification permission if you want action alerts

## Installation

The author’s installation walkthrough is available here:

- 🎥 **Installation tutorial**: https://www.youtube.com/watch?v=veaml3lK3_8

## How to Install

1. Go to the [Releases](https://github.com/Lian735/QuitonX/releases)
2. Download the latest .dmg file
3. Drag the App into the Applications folder
4. Open "QuitonX" from the Applications folder
5. A warning will show up
6. Go to System Settings -> Privacy & Security -> Scroll down until you see ""QuitonX" was blocked to protect your Mac." -> Click on "Open Anyway"

-> It should work now!

If it doesn't work or you have questions, join my [Discord Server]( https://discord.gg/u63YhXD3pC).

## First‑Run Setup

1. **Launch QuitonX** from Applications. The menu-bar icon appears right away.
2. **Grant Accessibility permission** when prompted so QuitonX can observe window events.
3. (Optional) **Allow Notifications** to see when apps are terminated.
4. Open **Settings** from the menu bar to tune behavior:
   - Enable/disable QuitonX
   - Confirmation delay before quitting
   - Allow quitting the frontmost app
   - Launch at login
   - Show notifications

## How It Works

- QuitonX monitors window creation/destruction events with Accessibility APIs.
- When the last window closes, it waits the configured delay and checks again.
- If the app still has zero windows, it’s terminated.
- Some system apps (like Finder and System Settings) are excluded automatically.

## Tips & Troubleshooting

- If nothing happens, confirm **Accessibility** permission is enabled in System Settings → Privacy & Security → Accessibility.
- If an app shouldn’t be auto-quit, temporarily **disable QuitonX** from the menu bar.
- If quitting feels too aggressive, **increase the confirmation delay**.
- Not every app is supported yet—compatibility will improve over time.

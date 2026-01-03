//
//  WindowObserver.swift
//  QuitonX
//
//  Created by Lian on 21.12.25.
//

import Cocoa
import ApplicationServices
import ApplicationServices.HIServices
import os.log

final class WindowObserver {
    fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QuitonX", category: "WindowObserver")
    fileprivate let debounceDelay: TimeInterval = 0.2
    fileprivate let settings = AppSettings.shared
    
    static let shared = WindowObserver()
    var enabled = true

    private var observers: [pid_t: AXObserver] = [:]
    fileprivate var lastFocusedWindow: [pid_t: AXUIElement] = [:]

    private init() {}

    private func elementsEqual(_ a: AXUIElement?, _ b: AXUIElement?) -> Bool {
        guard let a = a, let b = b else { return false }
        return CFEqual(a, b)
    }

    private func hasAppWindowsByCGWindowList(pid: pid_t) -> Bool {
        guard let infoList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            guard let ownerPid = info[kCGWindowOwnerPID as String] as? Int, ownerPid == Int(pid) else {
                continue
            }
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            if layer == 0 {
                return true
            }
        }
        return false
    }
    
    func evaluateAndTerminateIfWindowless(pid: pid_t) {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        guard app.activationPolicy == .regular && !isBlacklisted(app) else { return }
        
        let axApp = AXUIElementCreateApplication(pid)
        var windows: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windows)
        let count = (windows as? [Any])?.count ?? 0
        logger.debug("[Single] App \(app.localizedName ?? "unknown") PID: \(pid) has \(count) windows. AXError: \(String(describing: err.rawValue))")
        
        if count == 0 {
            // Recheck after a short delay to avoid terminating during full-screen/Space transitions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                var windows2: CFTypeRef?
                let err2 = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windows2)
                let count2 = (windows2 as? [Any])?.count ?? 0
                self.logger.debug("[Single-Recheck] App \(app.localizedName ?? "unknown") PID: \(pid) has \(count2) windows. AXError: \(String(describing: err2.rawValue))")
                if count2 == 0 {
                    if self.hasAppWindowsByCGWindowList(pid: pid) {
                        self.logger.debug("[Single] Abort terminate for \(app.localizedName ?? "unknown") PID: \(pid) — windows found via CGWindowList.")
                        return
                    }
                    let terminated = app.terminate()
                    self.logger.log("[Single] Terminating app \(app.localizedName ?? "unknown") PID: \(pid) with zero windows: \(terminated ? "success" : "failure")")
                } else {
                    self.logger.debug("[Single] Abort terminate for \(app.localizedName ?? "unknown") PID: \(pid) — windows reappeared.")
                }
            }
        }
    }

    func start() {
        guard ensureAccessibilityTrusted() else {
            logger.error("Accessibility permissions are not trusted. Cannot start WindowObserver.")
            return
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        let apps = NSWorkspace.shared.runningApplications
        for app in apps where app.activationPolicy == .regular && !isBlacklisted(app) {
            attachObserver(to: app)
        }
    }
    
    private func ensureAccessibilityTrusted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        logger.log("Accessibility trusted: \(trusted, privacy: .public)")
        return trusted
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication else { return }

        guard app.activationPolicy == .regular else { return }
        guard !isBlacklisted(app) else { return }

        attachObserver(to: app)
    }

    private func attachObserver(to app: NSRunningApplication) {
        guard app.activationPolicy == .regular else { return }
        guard !isBlacklisted(app) else { return }

        var observer: AXObserver?
        let error = AXObserverCreate(app.processIdentifier, axCallback, &observer)
        guard error == .success, let axObserver = observer else {
            logger.error("Failed to create AXObserver for app \(app.localizedName ?? "unknown") PID: \(app.processIdentifier) error: \(String(describing: error.rawValue))")
            return
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        func addNotification(_ notification: CFString) {
            let err = AXObserverAddNotification(axObserver, appElement, notification, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
            if err != .success {
                logger.error("Failed to add notification \(notification as String) for app \(app.localizedName ?? "unknown") PID: \(app.processIdentifier) error: \(String(describing: err.rawValue))")
            } else {
                logger.debug("Added notification \(notification as String) for app \(app.localizedName ?? "unknown") PID: \(app.processIdentifier)")
            }
        }

        addNotification(kAXWindowCreatedNotification as CFString)
        addNotification(kAXFocusedWindowChangedNotification as CFString)
        addNotification(kAXUIElementDestroyedNotification as CFString)

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(axObserver),
            .defaultMode
        )

        observers[app.processIdentifier] = axObserver

        attachWindowObservers(forAppPID: app.processIdentifier)
        
        logger.log("Attached AXObserver to app \(app.localizedName ?? "unknown") PID: \(app.processIdentifier)")
    }

    fileprivate func attachWindowObservers(forAppPID pid: pid_t) {
        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        if err != AXError.success {
            logger.error("Failed to get windows for app PID: \(pid), error: \(String(describing: err.rawValue))")
            return
        }
        guard let windows = windowsRef as? [AXUIElement] else { return }
        guard let observer = observers[pid] else { return }

        for window in windows {
            let err = AXObserverAddNotification(observer, window, kAXUIElementDestroyedNotification as CFString, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
            if err != .success {
                logger.error("Failed to add destroyed notification for window in app PID: \(pid), error: \(String(describing: err.rawValue))")
            } else {
                logger.debug("Added destroyed notification for a window in app PID: \(pid)")
            }
        }
    }
    
    func evaluateAndTerminateIfWindowless() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !isBlacklisted($0)
        }
        for app in apps {
            if app.processIdentifier == currentPID {
                logger.debug("Skipping self (QuitonX) PID: \(app.processIdentifier)")
                continue
            }
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windows: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windows)
            let count = (windows as? [Any])?.count ?? 0
            logger.debug("App \(app.localizedName ?? "unknown") PID: \(app.processIdentifier) has \(count) windows. AXError: \(String(describing: err.rawValue))")

            if count == 0 {
                if hasAppWindowsByCGWindowList(pid: app.processIdentifier) {
                    logger.debug("Skipping termination for \(app.localizedName ?? "unknown") PID: \(app.processIdentifier) — windows found via CGWindowList.")
                    continue
                }
                let terminated = app.terminate()
                logger.log("Terminating app \(app.localizedName ?? "unknown") PID: \(app.processIdentifier) with zero windows: \(terminated ? "success" : "failure")")
            }
        }
    }

    private func isBlacklisted(_ app: NSRunningApplication) -> Bool {
        let selfBundleID = Bundle.main.bundleIdentifier
        if app.bundleIdentifier == selfBundleID {
            return true
        }
        // Check whitelist from settings - if whitelisted, never terminate (return true)
        // Also exclude some static system apps never to terminate
        let staticBlacklist = ["Finder", "System Settings", "Systemeinstellungen"]
        if staticBlacklist.contains(app.localizedName ?? "") {
            return true
        }
        // Default fallback: not blacklisted
        return false
    }
}

private func axCallback(observer: AXObserver,
                        element: AXUIElement,
                        notification: CFString,
                        refcon: UnsafeMutableRawPointer?) {

    guard let refcon = refcon else { return }
    let manager = Unmanaged<WindowObserver>
        .fromOpaque(refcon)
        .takeUnretainedValue()

    manager.logger.debug("Received AX notification: \(notification as String)")
    guard manager.settings.enabled && manager.enabled else { return }

    var pid: pid_t = 0
    let pidErr = AXUIElementGetPid(element, &pid)
    if pidErr == .success {
        manager.logger.debug("Notification \(notification as String) for PID: \(pid)")
    } else {
        manager.logger.debug("Failed to get PID from element for notification \(notification as String)")
        return
    }

    if notification as String == String(kAXFocusedWindowChangedNotification) {
        let axApp = AXUIElementCreateApplication(pid)
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focused)
        if err == .success, let any = focused { let fw = any as! AXUIElement
            manager.lastFocusedWindow[pid] = fw
            manager.logger.debug("Updated last focused window for PID: \(pid)")
            manager.attachWindowObservers(forAppPID: pid)
        } else {
            manager.logger.debug("No focused window for PID: \(pid)")
        }
    } else if notification as String == String(kAXWindowCreatedNotification) {
        manager.logger.debug("Window created for PID: \(pid). Attaching window-level observers.")
        manager.attachWindowObservers(forAppPID: pid)
    } else if notification as String == String(kAXUIElementDestroyedNotification) {
        manager.logger.debug("Focused window destroyed for app PID: \(pid). Scheduling confirm-then-terminate.")
        let allowFront = manager.settings.allowQuittingFrontmost
        let delay = manager.settings.confirmationDelay

        if allowFront {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                manager.evaluateAndTerminateIfWindowless(pid: pid)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let currentFront = NSWorkspace.shared.frontmostApplication?.processIdentifier
                if currentFront != pid {
                    manager.evaluateAndTerminateIfWindowless(pid: pid)
                } else {
                    manager.logger.debug("Not terminating frontmost app PID: \(pid) because allowQuittingFrontmost is false")
                }
            }
        }
    }
}

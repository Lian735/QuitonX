//
//  AppDelegate.swift
//  QuitonX
//
//  Created by Lian on 21.12.25.
//


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    private let popover = NSPopover()
    let observer = WindowObserver.shared
    let settings = AppSettings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        observer.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(named: "quitonx")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)

            button.image = image
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 320)
        popover.contentViewController = NSHostingController(rootView: StatusMenuView())
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

//
//  QuitonXApp.swift
//  QuitonX
//
//  Created by Lian on 21.12.25.
//

import SwiftUI

@main
struct QuitonXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
          Settings {
              SettingsView()
          }
          .windowResizability(.automatic)         // allow the window to be resizable
          .defaultSize(width: 560, height: 420)   // pick a sensible starting size
    }
}

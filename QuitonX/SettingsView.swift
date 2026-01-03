import SwiftUI
import Combine
import AppKit
import ApplicationServices
import UserNotifications
import ServiceManagement

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var enabled: Bool = true
    @Published var allowQuittingFrontmost: Bool = true
    @Published var confirmationDelay: Double = 0.5
    @Published var showNotifications: Bool = true

    @Published var launchAtLogin: Bool = true {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }

    private init() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Login Item error:", error)
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    private var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    private var notificationsGranted: Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var granted = false

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            granted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            semaphore.signal()
        }

        semaphore.wait()
        return granted
    }

    private var allPermissionsGranted: Bool {
        accessibilityGranted && notificationsGranted
    }

    var body: some View {
        ZStack {
            Color.clear
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)

                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first(where: { $0.isVisible }) {
                            window.makeKeyAndOrderFront(nil)
                            window.orderFrontRegardless()
                        }
                    }
                }
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }

            VStack(spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QuitonX").font(.headline)
                    }
                    Spacer()
                    Toggle(isOn: $settings.enabled) { EmptyView() }
                        .toggleStyle(.switch)
                        .accessibilityLabel("Enable QuitonX")
                }

                Divider()

                // Permissions summary pill
                HStack(spacing: 8) {
                    Image(systemName: allPermissionsGranted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(allPermissionsGranted ? .green : .yellow)
                    Text(allPermissionsGranted ? "All permissions granted" : "Permissions missing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(allPermissionsGranted ? .green : .secondary)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                )

                // Form-like content
                VStack(alignment: .leading, spacing: 12) {
                    Text("General").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)

                    Toggle("Allow quitting frontmost app", isOn: $settings.allowQuittingFrontmost)
                        .help("Enable to allow quitting the app that is currently frontmost.")

                    Toggle("Launch at login", isOn: $settings.launchAtLogin)
                        .help("Automatically start QuitonX when you log in.")

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Confirmation delay")
                            Spacer()
                            Text(String(format: "%.2f s", settings.confirmationDelay))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.confirmationDelay, in: 0.2...1.0)
                            .help("Set the delay before confirmation action triggers.")
                    }

                    Toggle("Show notifications", isOn: $settings.showNotifications)
                        .help("Show notifications when actions are performed.")
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                )
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Unfortunately, not every app is supported yet. Im working on it :)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                )
            }
            .padding(16)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

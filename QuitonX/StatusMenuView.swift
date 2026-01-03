import SwiftUI
import ApplicationServices
import UserNotifications

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
        }
        .padding(.top, 6)
        .accessibilityHidden(true)
    }
}

struct StatusMenuView: View {
    @ObservedObject var settings = AppSettings.shared

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
        VStack(spacing: 12) {
            if !allPermissionsGranted {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Permissions missing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    SettingsLink {
                        Image(systemName: "gearshape")
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.yellow.opacity(0.12))
                )
            }
            HStack(alignment: .center, spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("QuitonX")
                        .font(.headline)
                }

                Spacer()
                
                Toggle(isOn: $settings.enabled) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .accessibilityLabel("Enable QuitonX")
            }

            Divider()

            HStack {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .tint(.blue.opacity(0.5))
                .buttonStyle(.glassProminent)
                .controlSize(.regular)
                Spacer()
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "xmark.circle")
                        .labelStyle(.titleAndIcon)
                }
                .tint(.red.opacity(0.5))
                .buttonStyle(.glassProminent)
            }
        }
        .padding(12)
        .frame(width: 270)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Toggle(title, isOn: $isOn)
                    .toggleStyle(.switch)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct StatusPill: View {
    let isOn: Bool
    var body: some View {
        Text(isOn ? "Enabled" : "Disabled")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(isOn ? .green.opacity(0.15) : .gray.opacity(0.15))
            )
            .foregroundStyle(isOn ? .green : .secondary)
    }
}

private struct NavigationShortcut: View {
    let label: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    StatusMenuView()
        .frame(width: 270)
}

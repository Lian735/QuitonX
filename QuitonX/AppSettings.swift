import Foundation
import Combine
import AppKit

final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()
    
    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: "SettingsModel_enabled")
        }
    }
    
    @Published var allowQuittingFrontmost: Bool {
        didSet {
            UserDefaults.standard.set(allowQuittingFrontmost, forKey: "SettingsModel_allowQuittingFrontmost")
        }
    }
    
    @Published var confirmationDelay: Double {
        didSet {
            UserDefaults.standard.set(confirmationDelay, forKey: "SettingsModel_confirmationDelay")
        }
    }
    
    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "SettingsModel_showNotifications")
        }
    }
    
    @Published var whitelist: [String] {
        didSet {
            UserDefaults.standard.set(whitelist, forKey: "SettingsModel_whitelist")
        }
    }
    
    @Published var blacklist: [String] {
        didSet {
            UserDefaults.standard.set(blacklist, forKey: "SettingsModel_blacklist")
        }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        
        // Load enabled or default true
        if defaults.object(forKey: "SettingsModel_enabled") != nil {
            enabled = defaults.bool(forKey: "SettingsModel_enabled")
        } else {
            enabled = true
        }
        
        // Load allowQuittingFrontmost or default true
        if defaults.object(forKey: "SettingsModel_allowQuittingFrontmost") != nil {
            allowQuittingFrontmost = defaults.bool(forKey: "SettingsModel_allowQuittingFrontmost")
        } else {
            allowQuittingFrontmost = true
        }
        
        // Load confirmationDelay or default 0.35
        let delay = defaults.double(forKey: "SettingsModel_confirmationDelay")
        confirmationDelay = delay == 0 ? 0.35 : delay
        
        // Load showNotifications or default false
        if defaults.object(forKey: "SettingsModel_showNotifications") != nil {
            showNotifications = defaults.bool(forKey: "SettingsModel_showNotifications")
        } else {
            showNotifications = false
        }
        
        // Load whitelist or default []
        if let loadedWhitelist = defaults.array(forKey: "SettingsModel_whitelist") as? [String] {
            whitelist = loadedWhitelist
        } else {
            whitelist = []
        }
        
        // Load blacklist or default ["com.apple.finder", "com.apple.systempreferences"]
        if let loadedBlacklist = defaults.array(forKey: "SettingsModel_blacklist") as? [String] {
            blacklist = loadedBlacklist
        } else {
            blacklist = ["com.apple.finder", "com.apple.systempreferences"]
        }
    }
    
    func isWhitelisted(_ app: NSRunningApplication) -> Bool {
        guard let bundleID = app.bundleIdentifier else {
            if let name = app.localizedName {
                return whitelist.contains(name)
            }
            return false
        }
        return whitelist.contains(bundleID)
    }
    
    func isBlacklisted(_ app: NSRunningApplication) -> Bool {
        guard let bundleID = app.bundleIdentifier else {
            if let name = app.localizedName {
                return blacklist.contains(name)
            }
            return false
        }
        return blacklist.contains(bundleID)
    }
}

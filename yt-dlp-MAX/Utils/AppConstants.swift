//
//  AppConstants.swift
//  yt-dlp-MAX
//
//  Central location for app-wide constants and configuration
//

import Foundation

struct AppConstants {
    // MARK: - Version
    
    /// The current app version from the bundle
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.0"
    }
    
    /// The current build number from the bundle
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Full version string including build number
    static var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
    
    // MARK: - App Info
    
    static let appName = "Fetcha"
    static let bundleIdentifier = "com.github.mstrslv13.fetcha-stream"
    static let githubRepo = "mstrslv13/fetcha-stream"
    
    // MARK: - Support
    
    static let supportEmail = "dev@fetcha.stream"
    static let githubIssuesURL = "https://github.com/mstrslv13/fetcha/issues"
    static let buyMeCoffeeURL = "https://buymeacoffee.com/mstrslva"
    
    // MARK: - Feature Flags
    
    static let enableAutoUpdate = true
    static let enableCrashReporting = false
    static let enableAnalytics = false
}
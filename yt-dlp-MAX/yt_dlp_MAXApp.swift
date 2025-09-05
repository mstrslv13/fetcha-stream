//
//  yt_dlp_MAXApp.swift
//  yt-dlp-MAX
//
//  Created by mstrslv on 8/22/25.
//

import SwiftUI
import AppKit

// App Delegate for dock menu support
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return DockMenuService.shared.getDockMenu()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize dock menu service
        _ = DockMenuService.shared
        
        // Check for required dependencies
        checkDependencies()
    }
    
    private func checkDependencies() {
        var missingDependencies: [String] = []
        var warnings: [String] = []
        
        // Check for yt-dlp
        let ytdlpPath = findYTDLP()
        if ytdlpPath == nil {
            missingDependencies.append("yt-dlp (required for downloading)")
        }
        
        // Check for ffmpeg
        let ffmpegPath = findFFmpeg()
        if ffmpegPath == nil {
            warnings.append("ffmpeg (optional but recommended for video processing)")
        }
        
        // Show notifications if dependencies are missing
        if !missingDependencies.isEmpty || !warnings.isEmpty {
            DispatchQueue.main.async {
                self.showDependencyAlert(missing: missingDependencies, warnings: warnings)
            }
        }
    }
    
    // Use YTDLPService's centralized binary detection
    private func findYTDLP() -> String? {
        // This is a temporary wrapper - should migrate to use YTDLPService directly
        let service = YTDLPService()
        // Access the centralized finder through service
        // Note: This requires making findBinary accessible or using the service methods
        let possiblePaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp",
            Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "bin")
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    private func findFFmpeg() -> String? {
        // This is a temporary wrapper - should migrate to use YTDLPService directly
        let possiblePaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg",
            Bundle.main.path(forResource: "ffmpeg", ofType: nil, inDirectory: "bin")
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    @MainActor
    private func showDependencyAlert(missing: [String], warnings: [String]) {
        let alert = NSAlert()
        
        if !missing.isEmpty {
            alert.messageText = "Missing Required Dependencies"
            alert.alertStyle = .critical
            alert.icon = NSImage(systemSymbolName: "xmark.octagon.fill", accessibilityDescription: nil)
            
            var message = "The following required dependencies are not installed:\n\n"
            for dep in missing {
                message += "• \(dep)\n"
            }
            message += "\nTo install yt-dlp, run:\nbrew install yt-dlp\n"
            
            if !warnings.isEmpty {
                message += "\nOptional dependencies missing:\n"
                for warning in warnings {
                    message += "• \(warning)\n"
                }
                message += "\nTo install ffmpeg, run:\nbrew install ffmpeg"
            }
            
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            
        } else if !warnings.isEmpty {
            alert.messageText = "Optional Dependencies Missing"
            alert.alertStyle = .informational
            alert.icon = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: nil)
            
            var message = "The following optional dependencies are not installed:\n\n"
            for warning in warnings {
                message += "• \(warning)\n"
            }
            message += "\nTo install ffmpeg for better video processing, run:\nbrew install ffmpeg\n\nThe app will work without these but with limited features."
            
            alert.informativeText = message
            alert.addButton(withTitle: "Continue")
        }
        
        alert.runModal()
    }
}

@main
struct yt_dlp_MAXApp: App {
    // ProcessManager removed - using ProcessExecutor instead
    @StateObject private var preferences = AppPreferences.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Process management handled by ProcessExecutor
        
        // Set the app icon (dock icon)
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
    }
    
    var body: some Scene {
        WindowGroup(preferences.privateMode ? "Fetcha (Private)" : "Fetcha") {
            ContentView()
                .onDisappear {
                    // Clean up when window closes
                    Task {
                        // Process termination handled by ProcessExecutor
                    }
                }
                .onAppear {
                    // Disable fullscreen mode for all windows
                    if let window = NSApplication.shared.windows.first {
                        window.collectionBehavior.remove(.fullScreenPrimary)
                        window.styleMask.remove(.fullScreen)
                        // Remove the fullscreen button
                        if let button = window.standardWindowButton(.zoomButton) {
                            button.isEnabled = false
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Fetcha") {
                    NSApplication.showAboutWindow()
                }
                .keyboardShortcut("A", modifiers: [.command, .shift])
            }
        }
    }
}

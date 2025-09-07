//
//  yt_dlp_MAXApp.swift
//  yt-dlp-MAX
//
//  Created by mstrslv on 8/22/25.
//

import SwiftUI
import AppKit
import Combine

// App Delegate for dock menu support and onboarding
class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return DockMenuService.shared.getDockMenu()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize dock menu service
        _ = DockMenuService.shared
        
        // Check for onboarding needs
        Task {
            await checkOnboarding()
        }
    }
    
    @MainActor
    private func checkOnboarding() async {
        let coordinator = OnboardingCoordinator.shared
        await coordinator.checkIfOnboardingNeeded()
        
        if coordinator.isOnboardingRequired {
            showOnboardingWindow()
        }
        
        // Monitor onboarding state changes
        coordinator.$isOnboardingRequired
            .sink { [weak self] required in
                Task { @MainActor in
                    if !required {
                        self?.onboardingWindow?.close()
                        self?.onboardingWindow = nil
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func showOnboardingWindow() {
        // Don't show if already visible
        guard onboardingWindow == nil else { return }
        
        let onboardingView = OnboardingView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome to Fetcha"
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.level = .floating // Keep on top during onboarding
        
        // Prevent closing if dependencies are missing
        window.delegate = OnboardingWindowDelegate()
        
        self.onboardingWindow = window
    }
}

// Window delegate to control onboarding window behavior
class OnboardingWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Only allow closing if onboarding is complete or not required
        let coordinator = OnboardingCoordinator.shared
        if coordinator.dependencies?.ytdlp.isInstalled == true {
            return true // Allow closing if at least yt-dlp is installed
        }
        return !coordinator.isOnboardingRequired
    }
}

@main
struct yt_dlp_MAXApp: App {
    // ProcessManager removed - using ProcessExecutor instead
    @StateObject private var preferences = AppPreferences.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var preferencesWindow: NSWindow?
    @State private var showingBugReport = false
    
    init() {
        // Process management handled by ProcessExecutor
        
        // Set the app icon (dock icon)
        // AppIcon is handled automatically by the asset catalog
        // No need to set it manually
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
                .sheet(isPresented: $showingBugReport) {
                    BugReportView()
                        .frame(width: 600, height: 500)
                }
        }
        .windowResizability(.contentSize)
        .commands {
            // Fetcha Menu
            CommandGroup(replacing: .appInfo) {
                Button("About Fetcha") {
                    NSApplication.showAboutWindow()
                }
                
                Divider()
                
                Button("Preferences...") {
                    openPreferencesWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
                
                Button("Check for Updates...") {
                    Task {
                        await checkForUpdates()
                    }
                }
            }
            
            // File Menu additions
            CommandGroup(after: .newItem) {
                Button("Import URLs from File...") {
                    // FUTURE: Phase 2 - Batch import from text file
                }
                .keyboardShortcut("O", modifiers: .command)
                
                Divider()
                
                Button("Open Downloads Folder") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: preferences.resolvedDownloadPath))
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])
            }
            
            // View Menu
            CommandMenu("View") {
                Button("Show Download Queue") {
                    // FUTURE: Phase 2 - Queue window
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Show Completed Downloads") {
                    // FUTURE: Phase 2 - History window
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Divider()
                
                Button("Toggle History Panel") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleHistoryPanel"), object: nil)
                }
                .keyboardShortcut("H", modifiers: .command)
                
                Button("Toggle Details Panel") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleDetailsPanel"), object: nil)
                }
                .keyboardShortcut("D", modifiers: .command)
            }
            
            // Tools Menu
            CommandMenu("Tools") {
                Button("Check Dependencies...") {
                    Task {
                        await checkDependencies()
                    }
                }
                
                Button("Browser Integration Setup...") {
                    // Show cookie permission settings
                    openPreferencesWindow()
                }
                
                Divider()
                
                Button("Clear Cache") {
                    DependencyManager.shared.clearCache()
                    PersistentDebugLogger.shared.clearLogs()
                }
                
                Button("Export Debug Logs...") {
                    exportDebugLogs()
                }
            }
            
            // Help Menu
            CommandGroup(replacing: .help) {
                Button("Fetcha Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/mstrslv13/fetcha-stream/wiki")!)
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Button("Quick Start Guide") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/mstrslv13/fetcha-stream#quick-start")!)
                }
                
                Divider()
                
                Button("Report a Bug...") {
                    showingBugReport = true
                }
                
                Button("Request a Feature...") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/mstrslv13/fetcha-stream/issues/new?template=feature_request.md")!)
                }
                
                Divider()
                
                Button("View on GitHub") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/mstrslv13/fetcha-stream")!)
                }
            }
        }
    }
    
    // Helper functions
    private func openPreferencesWindow() {
        // Check if preferences window already exists and is visible
        if let existingWindow = preferencesWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new preferences window
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 850, height: 700))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Store reference to window
        preferencesWindow = window
        
        // Clean up reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            self.preferencesWindow = nil
        }
    }
    
    private func checkForUpdates() async {
        // FUTURE: Phase 3 - Auto-update functionality
        PersistentDebugLogger.shared.log("Check for updates requested", level: .info)
    }
    
    private func checkDependencies() async {
        let coordinator = OnboardingCoordinator.shared
        coordinator.dependencies = await coordinator.checkDependencies()
        coordinator.currentStep = .dependencyCheck
        coordinator.isOnboardingRequired = true
    }
    
    private func exportDebugLogs() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "fetcha-debug-\(Date().timeIntervalSince1970).log"
        savePanel.allowedContentTypes = [.log]
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                let logs = PersistentDebugLogger.shared.getFormattedLogs()
                try? logs.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

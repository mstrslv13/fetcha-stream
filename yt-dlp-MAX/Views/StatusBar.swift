//
//  StatusBar.swift
//  yt-dlp-MAX
//
//  Bottom status bar with settings, notifications, version, and dev tools toggle
//

import SwiftUI

struct StatusBar: View {
    @Binding var showDevTools: Bool
    @Binding var showNotifications: Bool
    @StateObject private var notificationCenter = AppNotificationCenter.shared
    @State private var statusText = "Ready"
    @State private var isCheckingForUpdates = false
    
    let appVersion = AppConstants.appVersion
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Settings and Notifications
            HStack(spacing: 8) {
                // Settings button
                Button(action: openPreferences) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Preferences (⌘,)")
                
                // Notifications button with badge
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showNotifications.toggle()
                    }
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: showNotifications ? "bell.fill" : "bell")
                            .font(.system(size: 12))
                            .foregroundColor(showNotifications ? .accentColor : .secondary)
                        
                        // Badge if there are unread notifications
                        if notificationCenter.unreadCount > 0 {
                            Text("\(min(notificationCenter.unreadCount, 99))")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Circle().fill(Color.red))
                                .offset(x: 6, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help("Notifications (\(notificationCenter.unreadCount) unread) - Click to \(showNotifications ? "close" : "open")")
            }
            
            // Center - Status text
            Text(statusText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side - Version and Dev Tools
            HStack(spacing: 12) {
                // Version number (clickable)
                Button(action: {
                    showAboutWindow()
                    checkForUpdates()
                }) {
                    HStack(spacing: 4) {
                        if isCheckingForUpdates {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                        }
                        Text("v\(appVersion)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Version \(appVersion) - Click to check for updates")
                
                // Dev Tools toggle
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDevTools.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench")
                            .font(.system(size: 11))
                        Text("Dev Tools")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(showDevTools ? .accentColor : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(showDevTools ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(showDevTools ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Toggle Dev Tools (⌥⌘I)")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1),
            alignment: .top
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StatusUpdate"))) { notification in
            if let text = notification.object as? String {
                statusText = text
            }
        }
    }
    
    private static var preferencesWindow: NSWindow?
    
    private func openPreferences() {
        // Toggle preferences window
        if let existingWindow = StatusBar.preferencesWindow, existingWindow.isVisible {
            existingWindow.close()
            StatusBar.preferencesWindow = nil
            return
        }
        
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 850, height: 700))
        window.styleMask = [.titled, .closable, .miniaturizable] // No .resizable or fullscreen
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        StatusBar.preferencesWindow = window
        
        // Clear reference when closed
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            StatusBar.preferencesWindow = nil
        }
    }
    
    private func showAboutWindow() {
        NSApplication.showAboutWindow()
    }
    
    private func checkForUpdates() {
        isCheckingForUpdates = true
        Task {
            await UpdateChecker.shared.checkForUpdates()
            await MainActor.run {
                isCheckingForUpdates = false
            }
        }
    }
}
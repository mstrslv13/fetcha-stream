//
//  NotificationCenter.swift
//  yt-dlp-MAX
//
//  Manages in-app notifications and alerts
//

import SwiftUI
import Combine

@MainActor
final class AppNotificationCenter: ObservableObject {
    static let shared = AppNotificationCenter()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private init() {
        loadStoredNotifications()
    }
    
    struct AppNotification: Identifiable, Codable {
        var id = UUID()
        let timestamp: Date
        let type: NotificationType
        let title: String
        let message: String
        var isRead: Bool = false
        let actionURL: String?
        
        init(type: NotificationType, title: String, message: String, actionURL: String? = nil) {
            self.timestamp = Date()
            self.type = type
            self.title = title
            self.message = message
            self.actionURL = actionURL
        }
    }
    
    enum NotificationType: String, Codable {
        case error = "error"
        case warning = "warning"
        case info = "info"
        case success = "success"
        case update = "update"
        case dependency = "dependency"
        case cookieSuccess = "cookieSuccess"
        case cookieFailure = "cookieFailure"
        case cookieWarning = "cookieWarning"
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .update: return "arrow.down.circle.fill"
            case .dependency: return "gearshape.2.fill"
            case .cookieSuccess: return "checkmark.seal.fill"
            case .cookieFailure: return "exclamationmark.shield.fill"
            case .cookieWarning: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            case .success: return .green
            case .update: return .purple
            case .dependency: return .gray
            case .cookieSuccess: return .green
            case .cookieFailure: return .red
            case .cookieWarning: return .orange
            }
        }
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        updateUnreadCount()
        saveNotifications()
        
        // Keep only last 100 notifications
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
    }
    
    func addNotification(type: NotificationType, title: String, message: String, actionURL: String? = nil) {
        let notification = AppNotification(type: type, title: title, message: message, actionURL: actionURL)
        addNotification(notification)
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
        }
    }
    
    func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
    }
    
    func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
    }
    
    func clearOld(olderThan days: Int = 7) {
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        notifications.removeAll { $0.timestamp < cutoffDate }
        updateUnreadCount()
        saveNotifications()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Error Convenience Methods
    
    func notifyDownloadError(_ error: String, url: String) {
        addNotification(
            type: .error,
            title: "Download Failed",
            message: "Error downloading \(url): \(error)"
        )
    }
    
    func notifyDependencyMissing(_ dependency: String) {
        addNotification(
            type: .dependency,
            title: "Missing Dependency",
            message: "\(dependency) is not installed or not found in PATH"
        )
    }
    
    func notifyUpdateAvailable(version: String, url: String) {
        addNotification(
            type: .update,
            title: "Update Available",
            message: "Fetcha v\(version) is available for download",
            actionURL: url
        )
    }
    
    func notifyFFmpegError(_ error: String) {
        addNotification(
            type: .error,
            title: "FFmpeg Error",
            message: "Media processing failed: \(error)"
        )
    }
    
    func notifyQueueComplete(count: Int) {
        addNotification(
            type: .success,
            title: "Queue Complete",
            message: "Successfully downloaded \(count) item\(count == 1 ? "" : "s")"
        )
    }
    
    // MARK: - Cookie Notifications
    
    func notifyCookieSuccess(browser: String, count: Int? = nil) {
        let message = count != nil ? 
            "\(browser) cookies successfully imported! (\(count!) cookies)" :
            "\(browser) cookies successfully imported!"
        addNotification(
            type: .cookieSuccess,
            title: "Cookies Imported",
            message: message
        )
    }
    
    func notifyCookieFailure(browser: String, reason: String? = nil) {
        let message = reason ?? "Failed to import \(browser) cookies. Please close \(browser) and try again."
        addNotification(
            type: .cookieFailure,
            title: "Cookie Import Failed",
            message: message
        )
    }
    
    func notifyCookieWarning(browser: String, message: String) {
        addNotification(
            type: .cookieWarning,
            title: "Cookie Import Warning",
            message: "\(browser): \(message)"
        )
    }
    
    // MARK: - Persistence
    
    private var notificationsURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("Fetcha", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("notifications.json")
    }
    
    private func saveNotifications() {
        do {
            let data = try JSONEncoder().encode(notifications)
            try data.write(to: notificationsURL)
        } catch {
            print("Failed to save notifications: \(error)")
        }
    }
    
    private func loadStoredNotifications() {
        guard FileManager.default.fileExists(atPath: notificationsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: notificationsURL)
            notifications = try JSONDecoder().decode([AppNotification].self, from: data)
            updateUnreadCount()
        } catch {
            print("Failed to load notifications: \(error)")
        }
    }
}
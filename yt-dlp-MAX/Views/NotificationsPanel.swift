//
//  NotificationsPanel.swift
//  yt-dlp-MAX
//
//  Notification center panel for displaying in-app notifications
//

import SwiftUI

struct NotificationsPanel: View {
    @StateObject private var notificationCenter = AppNotificationCenter.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !notificationCenter.notifications.isEmpty {
                    Button(action: {
                        notificationCenter.clearAll()
                    }) {
                        Text("Clear All")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding()
            .background(themeManager.colors.background)
            
            Divider()
            
            // Notifications list
            if notificationCenter.notifications.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Notifications")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("You're all caught up!")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textTertiary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.colors.background)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(notificationCenter.notifications) { notification in
                            NotificationRow(notification: notification)
                            
                            if notification.id != notificationCenter.notifications.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
            }
        }
        .onAppear {
            // Mark all as read when panel opens
            notificationCenter.markAllAsRead()
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotificationCenter.AppNotification
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.colors.textTertiary)
            }
            
            Spacer()
            
            // Action button if applicable
            if notification.type == .update,
               let actionURL = notification.actionURL {
                Button(action: {
                    if let url = URL(string: actionURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Download")
                        .font(.caption)
                }
                .buttonStyle(.link)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isHovering ? themeManager.colors.surfaceHover : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var iconName: String {
        switch notification.type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .update:
            return "arrow.down.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .dependency:
            return "gearshape.fill"
        case .cookieSuccess:
            return "checkmark.seal.fill"
        case .cookieFailure:
            return "exclamationmark.shield.fill"
        case .cookieWarning:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .success:
            return .green
        case .error:
            return .red
        case .update:
            return .blue
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .dependency:
            return .purple
        case .cookieSuccess:
            return .green
        case .cookieFailure:
            return .red
        case .cookieWarning:
            return .orange
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
}

#Preview {
    NotificationsPanel(isShowing: .constant(true))
        .frame(width: 400, height: 500)
}
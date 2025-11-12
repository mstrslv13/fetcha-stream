//
//  DevToolsPanel.swift
//  yt-dlp-MAX
//
//  Bottom sliding panel for debug console and dev tools
//

import SwiftUI

struct DevToolsPanel: View {
    @Binding var isExpanded: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var panelHeight: CGFloat = 250
    @State private var isDragging = false
    @State private var selectedTab = "console"
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    @State private var selectedLogType = "All"
    @State private var searchText = ""
    @State private var showingExportView = false
    
    let minHeight: CGFloat = 200
    let maxHeight: CGFloat = 600
    let logTypes = ["All", "Error", "Warn", "Info", "yt-dlp", "ffmpeg"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Rectangle()
                .fill(Color.clear)
                .frame(height: 6)
                .overlay(
                    Capsule()
                        .fill(themeManager.colors.divider)
                        .frame(width: 36, height: 4)
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let newHeight = panelHeight - value.translation.height
                            panelHeight = min(max(newHeight, minHeight), maxHeight)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            
            // Toolbar
            HStack(spacing: 12) {
                // Tab selector
                HStack(spacing: 1) {
                    TabButton(title: "Console", icon: "terminal", isSelected: selectedTab == "console") {
                        selectedTab = "console"
                    }
                    TabButton(title: "Network", icon: "network", isSelected: selectedTab == "network") {
                        selectedTab = "network"
                    }
                    .disabled(true) // FUTURE: Phase 2 - Network monitoring
                    .opacity(0.5)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Log type filters
                HStack(spacing: 4) {
                    ForEach(logTypes, id: \.self) { type in
                        DevToolsFilterPill(title: type, isSelected: selectedLogType == type) {
                            selectedLogType = type
                        }
                    }
                }
                
                
                Spacer()
                
                // Search field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 180)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.colors.surface.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(themeManager.colors.divider, lineWidth: 0.5)
                )
                
                // Action buttons
                Button(action: copyAllLogs) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Copy all visible logs")
                
                Button(action: { showingExportView = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Export logs")
                
                Button(action: clearLogs) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Clear logs")
                
                // Close button
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.colors.background)
            
            Divider()
            
            // Content area
            if selectedTab == "console" {
                SelectableDebugConsole(
                    logs: .constant(filteredLogs),
                    filter: selectedLogType
                )
                .background(themeManager.colors.surface)
            } else {
                // FUTURE: Network tab content
                VStack {
                    Spacer()
                    Text("Network monitoring coming soon")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.colors.surface)
            }
        }
        .frame(height: isExpanded ? panelHeight : 0)
        .clipped()
        .background(themeManager.colors.background)
        .overlay(
            Rectangle()
                .fill(themeManager.colors.divider)
                .frame(height: 1),
            alignment: .top
        )
        .sheet(isPresented: $showingExportView) {
            ExportLogsView()
                .frame(width: 600, height: 650)
        }
    }
    
    private var filteredLogs: [PersistentDebugLogger.DebugLog] {
        var logs = debugLogger.logs
        
        // Apply type filter
        switch selectedLogType {
        case "Error":
            logs = logs.filter { $0.level == .error }
        case "Network":
            logs = logs.filter { 
                $0.message.contains("HTTP") || 
                $0.message.contains("download") || 
                $0.message.contains("fetch")
            }
        case "yt-dlp":
            logs = logs.filter { 
                $0.message.contains("yt-dlp") || 
                $0.details?.contains("yt-dlp") ?? false 
            }
        case "ffmpeg":
            logs = logs.filter { 
                $0.message.contains("ffmpeg") || 
                $0.message.contains("FFmpeg") ||
                $0.details?.contains("ffmpeg") ?? false ||
                $0.details?.contains("FFmpeg") ?? false
            }
        case "Warn":
            logs = logs.filter { $0.level == .warning }
        case "Info":
            logs = logs.filter { $0.level == .info }
        default:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            logs = logs.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                ($0.details?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return logs
    }
    
    private func copyAllLogs() {
        let logText = filteredLogs.map { log in
            let timeString = DateFormatter.localizedString(from: log.timestamp, dateStyle: .none, timeStyle: .medium)
            var text = "[\(timeString)] [\(log.level.rawValue)] \(log.message)"
            if let details = log.details {
                text += "\n    \(details)"
            }
            return text
        }.joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }
    
    private func clearLogs() {
        PersistentDebugLogger.shared.clearLogs()
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                isSelected ? themeManager.colors.surfaceSelected : Color.clear
            )
        }
        .buttonStyle(.plain)
    }
}

struct DevToolsFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor : themeManager.colors.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.clear : themeManager.colors.divider, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}


import SwiftUI

struct FileHistoryPanel: View {
    @State private var selectedTab = "history"
    @State private var searchText = ""
    @State private var filterType = "All"
    @StateObject private var downloadHistory = DownloadHistory.shared
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    
    let filterOptions = ["All", "Completed", "Failed", "In Progress"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HStack(spacing: 20) {
                Button(action: { selectedTab = "history" }) {
                    Text("History")
                        .font(.system(size: 13, weight: selectedTab == "history" ? .medium : .regular))
                        .foregroundColor(selectedTab == "history" ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: { selectedTab = "debug" }) {
                    Text("Debug")
                        .font(.system(size: 13, weight: selectedTab == "debug" ? .medium : .regular))
                        .foregroundColor(selectedTab == "debug" ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search and filter bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                
                Picker("", selection: $filterType) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            // Content based on selected tab
            if selectedTab == "history" {
                FileHistoryList(searchText: searchText, filterType: filterType)
            } else {
                DebugLogsView()
            }
        }
    }
}

struct FileHistoryList: View {
    let searchText: String
    let filterType: String
    @StateObject private var downloadHistory = DownloadHistory.shared
    
    var filteredHistory: [DownloadHistory.DownloadRecord] {
        var items = Array(downloadHistory.history)
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.url.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by timestamp
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredHistory, id: \.videoId) { item in
                    FileHistoryRow(item: item)
                    Divider()
                        .padding(.leading, 12)
                }
            }
        }
    }
}

struct FileHistoryRow: View {
    let item: DownloadHistory.DownloadRecord
    
    var statusIcon: String {
        return "checkmark.circle.fill"
    }
    
    var statusColor: Color {
        return .green
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                
                Text(formatDate(item.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let fileSize = item.fileSize {
                Text(formatFileSize(fileSize))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            // Select item for details view
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DebugLogsView: View {
    @State private var selectedLogType = "All"
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    
    let logTypes = ["All", "yt-dlp", "ffmpeg", "App"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Log type selector
            HStack {
                ForEach(logTypes, id: \.self) { type in
                    Button(action: { selectedLogType = type }) {
                        Text(type)
                            .font(.system(size: 11))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(selectedLogType == type ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Open console button
                Button(action: {
                    openDebugConsole()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "terminal")
                            .font(.system(size: 10))
                        Text("Console")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            // Debug logs
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredLogs, id: \.id) { entry in
                            DebugLogRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                }
                .onAppear {
                    if let lastEntry = filteredLogs.last {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
                .onChange(of: debugLogger.logs.count) { _, _ in
                    if let lastEntry = filteredLogs.last {
                        withAnimation {
                            proxy.scrollTo(lastEntry.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    var filteredLogs: [PersistentDebugLogger.DebugLog] {
        switch selectedLogType {
        case "yt-dlp":
            return debugLogger.logs.filter { $0.message.contains("yt-dlp") || $0.details?.contains("yt-dlp") ?? false }
        case "ffmpeg":
            return debugLogger.logs.filter { $0.message.contains("ffmpeg") || $0.details?.contains("ffmpeg") ?? false }
        case "App":
            return debugLogger.logs.filter { 
                !$0.message.contains("yt-dlp") && !$0.message.contains("ffmpeg") &&
                !(($0.details?.contains("yt-dlp") ?? false) || ($0.details?.contains("ffmpeg") ?? false))
            }
        default:
            return debugLogger.logs
        }
    }
    
    func openDebugConsole() {
        let debugView = DebugView()
        let hostingController = NSHostingController(rootView: debugView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Debug Console"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
    }
}

struct DebugLogRow: View {
    let entry: PersistentDebugLogger.DebugLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(entry.level.color)
                    .frame(width: 6, height: 6)
                
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(entry.message)
                    .font(.system(size: 11))
                    .lineLimit(2)
            }
            
            if let details = entry.details {
                Text(details)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
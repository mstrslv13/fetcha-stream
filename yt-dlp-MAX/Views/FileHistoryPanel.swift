import SwiftUI

struct FileHistoryPanel: View {
    @Binding var selectedItem: DownloadHistory.DownloadRecord?
    @State private var selectedTab = "history"
    @State private var searchText = ""
    @State private var filterType = "All"
    @StateObject private var downloadHistory = DownloadHistory.shared
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    
    let filterOptions = ["All", "Completed", "Failed", "In Progress"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Warning banner for large history (9000+ items)
            if downloadHistory.history.count >= 9000 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("History contains \(downloadHistory.history.count) items")
                        .font(.system(size: 11, weight: .medium))
                    
                    Text("Performance may be affected")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Clear old history items
                        downloadHistory.clearOldRecords(olderThanDays: 30)
                    }) {
                        Text("Clear Old")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .overlay(
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
            
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
                FileHistoryList(searchText: searchText, filterType: filterType, selectedItem: $selectedItem)
            } else {
                DebugLogsView()
            }
        }
    }
}

struct FileHistoryList: View {
    let searchText: String
    let filterType: String
    @Binding var selectedItem: DownloadHistory.DownloadRecord?
    @StateObject private var downloadHistory = DownloadHistory.shared
    
    // PERFORMANCE FIX: Cache filtered results and only recalculate when inputs change
    @State private var cachedFilteredHistory: [DownloadHistory.DownloadRecord] = []
    @State private var lastSearchText = ""
    @State private var lastFilterType = "All"
    @State private var lastHistoryCount = 0
    
    var filteredHistory: [DownloadHistory.DownloadRecord] {
        // Only recalculate if inputs have changed
        if searchText == lastSearchText && 
           filterType == lastFilterType && 
           downloadHistory.history.count == lastHistoryCount {
            return cachedFilteredHistory
        }
        
        // Limit to most recent 1000 items for performance
        var items = Array(downloadHistory.history.prefix(1000))
        
        // Apply filter type
        switch filterType {
        case "Completed":
            break
        case "Failed":
            items = []
        case "In Progress":
            items = []
        default:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.url.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by timestamp (already sorted in history, so only sort filtered results)
        let sorted = items.sorted { $0.timestamp > $1.timestamp }
        
        // Update cache
        DispatchQueue.main.async {
            self.cachedFilteredHistory = sorted
            self.lastSearchText = searchText
            self.lastFilterType = filterType
            self.lastHistoryCount = downloadHistory.history.count
        }
        
        return sorted
    }
    
    var body: some View {
        ScrollView {
            // PERFORMANCE FIX: Use LazyVStack for efficient rendering of large lists
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(filteredHistory.prefix(500), id: \.videoId) { item in
                    FileHistoryRow(
                        item: item,
                        isSelected: selectedItem?.videoId == item.videoId,
                        onSelect: {
                            selectedItem = item
                            // Notify MediaControlBar of selection
                            NotificationCenter.default.post(
                                name: NSNotification.Name("HistoryItemSelected"),
                                object: nil,
                                userInfo: ["item": item]
                            )
                        }
                    )
                    Divider()
                        .padding(.leading, 12)
                }
                
                // Show a message if list is truncated
                if filteredHistory.count > 500 {
                    HStack {
                        Spacer()
                        Text("Showing first 500 of \(filteredHistory.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                }
            }
        }
    }
}

struct FileHistoryRow: View {
    let item: DownloadHistory.DownloadRecord
    let isSelected: Bool
    let onSelect: () -> Void
    
    var statusIcon: String {
        return "checkmark.circle.fill"
    }
    
    var statusColor: Color {
        return .green
    }
    
    // Check if there's a separate audio file for this download
    var hasAudioFile: Bool {
        if let actualPath = item.actualFilePath {
            let fileURL = URL(fileURLWithPath: actualPath)
            let basePath = fileURL.deletingPathExtension()
            let audioExtensions = ["mp3", "m4a", "opus", "ogg", "wav", "aac", "flac"]
            
            // Check if any audio file with the same base name exists
            for ext in audioExtensions {
                let audioPath = basePath.appendingPathExtension(ext)
                if FileManager.default.fileExists(atPath: audioPath.path) {
                    return true
                }
            }
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    
                    // Show audio indicator if separate audio file exists
                    if hasAudioFile {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .help("Separate audio file available")
                    }
                }
                
                HStack(spacing: 4) {
                    Text(formatDate(item.timestamp))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    if !item.filename.isEmpty && item.filename != item.title {
                        Text("• \(item.filename)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
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
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button(action: {
                // Open the file using DownloadHistory's method
                if let actualFileURL = DownloadHistory.shared.findActualFile(for: item) {
                    NSWorkspace.shared.open(actualFileURL)
                } else {
                    // File doesn't exist, show error or parent folder
                    let url = URL(fileURLWithPath: item.resolvedFilePath)
                    if FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) {
                        NSWorkspace.shared.open(url.deletingLastPathComponent())
                    }
                }
            }) {
                Label("Open File", systemImage: "play.circle")
            }
            
            Button(action: {
                // Show in Finder using DownloadHistory's method
                if let actualFileURL = DownloadHistory.shared.findActualFile(for: item) {
                    NSWorkspace.shared.activateFileViewerSelecting([actualFileURL])
                } else {
                    let url = URL(fileURLWithPath: item.resolvedFilePath)
                    if FileManager.default.fileExists(atPath: url.path) {
                        NSWorkspace.shared.open(url)
                    } else {
                        NSWorkspace.shared.open(url.deletingLastPathComponent())
                    }
                }
            }) {
                Label("Show in Finder", systemImage: "folder")
            }
            
            Button(action: {
                // Open source URL in browser
                if let url = URL(string: item.url) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Open in Browser", systemImage: "safari")
            }
            
            Divider()
            
            Button(action: {
                // Copy file path - use actual file path if available
                let pathToCopy = item.actualFilePath ?? item.downloadPath
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pathToCopy, forType: .string)
            }) {
                Label("Copy File Path", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                // Copy source URL
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url, forType: .string)
            }) {
                Label("Copy Source URL", systemImage: "link")
            }
            
            Divider()
            
            if let uploader = item.uploader {
                Button(action: {}) {
                    Label(uploader, systemImage: "person.circle")
                }
                .disabled(true)
            }
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
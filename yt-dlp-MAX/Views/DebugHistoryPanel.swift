import SwiftUI

struct DebugHistoryPanel: View {
    @StateObject private var logger = PersistentDebugLogger.shared
    @State private var selectedSessionId: UUID?
    @State private var filterLevel: PersistentDebugLogger.DebugLog.LogLevel?
    @State private var searchText = ""
    
    var filteredLogs: [PersistentDebugLogger.DebugLog] {
        let logsToFilter = selectedSessionId != nil ? 
            logger.getLogsForSession(selectedSessionId!) : logger.logs
        
        return logsToFilter.filter { log in
            let matchesLevel = filterLevel == nil || log.level == filterLevel
            let matchesSearch = searchText.isEmpty || 
                log.message.localizedCaseInsensitiveContains(searchText) ||
                (log.details?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesLevel && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Debug History")
                    .font(.headline)
                Spacer()
                
                Menu {
                    Button("Clear Current Session") {
                        logger.clear()
                    }
                    Button("Clear All History") {
                        logger.clearAll()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    FilterChip(
                        title: "All",
                        isSelected: filterLevel == nil
                    ) {
                        filterLevel = nil
                    }
                    
                    ForEach(PersistentDebugLogger.DebugLog.LogLevel.allCases, id: \.self) { level in
                        FilterChip(
                            title: level.rawValue.capitalized,
                            icon: level.icon,
                            color: level.color,
                            isSelected: filterLevel == level
                        ) {
                            filterLevel = level
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            
            Divider()
            
            
            // Logs list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                    }
                }
                .padding(4)
            }
            
            // Footer with log count
            HStack {
                Text("\(filteredLogs.count) logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SessionRow: View {
    let session: PersistentDebugLogger.SessionLog
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isCurrent ? "circle.fill" : "clock")
                    .foregroundColor(isCurrent ? .green : .secondary)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startTime, style: .time)
                        .font(.caption)
                        .fontWeight(isCurrent ? .medium : .regular)
                    
                    HStack {
                        Text("\(session.logCount) logs")
                        Text("•")
                        Text(session.formattedDuration)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct LogRow: View {
    let log: PersistentDebugLogger.DebugLog
    
    var messageColor: Color {
        switch log.level {
        case .error:
            return .red
        case .warning:
            return .yellow
        case .success:
            return .green
        case .command:
            return .purple
        default:
            return .primary
        }
    }
    
    var messagePrefix: String {
        // Add prefix for yt-dlp and ffmpeg messages
        if log.message.contains("yt-dlp") || log.message.contains("Executing yt-dlp") {
            return "[yt-dlp] "
        } else if log.message.contains("ffmpeg") || log.message.contains("Merging") {
            return "[ffmpeg] "
        }
        return ""
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(log.timestamp, style: .time)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.secondary.opacity(0.6))
                .frame(width: 50)
            
            // Show the actual message/details without "show details" button
            if let details = log.details, !details.isEmpty {
                Text(messagePrefix + details)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(messageColor)
                    .textSelection(.enabled)
            } else {
                Text(messagePrefix + log.message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(messageColor)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = .primary
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
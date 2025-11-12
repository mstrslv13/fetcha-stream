//
//  ExportLogsView.swift
//  yt-dlp-MAX
//
//  Enhanced log export with filtering by type and date/time range
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportLogsView: View {
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    @State private var selectedLogTypes: Set<String> = ["All"]
    @State private var useTimeRange = false
    @State private var startDate = Date().addingTimeInterval(-86400) // 24 hours ago
    @State private var endDate = Date()
    @State private var exportFormat: ExportFormat = .text
    @State private var includeDetails = true
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss
    
    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text (.txt)"
        case json = "JSON (.json)"
        case csv = "CSV (.csv)"
        
        var fileExtension: String {
            switch self {
            case .text: return "txt"
            case .json: return "json"
            case .csv: return "csv"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .text: return .plainText
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
    }
    
    let logTypes = ["All", "Errors", "Warnings", "Info", "Success", "Commands", "yt-dlp", "ffmpeg", "App"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Export Logs")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Filters
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Log Type Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Log Types", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(logTypes, id: \.self) { type in
                                LogTypeToggle(
                                    type: type,
                                    isSelected: selectedLogTypes.contains(type),
                                    action: { toggleLogType(type) }
                                )
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Time Range Filter
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Time Range", systemImage: "clock")
                                .font(.headline)
                            
                            Toggle("", isOn: $useTimeRange)
                                .labelsHidden()
                        }
                        
                        if useTimeRange {
                            HStack(spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("From:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("To:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Export Options
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Export Options", systemImage: "square.and.arrow.up")
                            .font(.headline)
                        
                        Picker("Format:", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Toggle("Include detailed information", isOn: $includeDetails)
                            .help("Include additional details and stack traces in the export")
                    }
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Export Preview", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        
                        let filteredLogs = getFilteredLogs()
                        HStack {
                            StatBox(label: "Total Logs", value: "\(filteredLogs.count)")
                            StatBox(label: "Errors", value: "\(filteredLogs.filter { $0.level == .error }.count)", color: .red)
                            StatBox(label: "Warnings", value: "\(filteredLogs.filter { $0.level == .warning }.count)", color: .orange)
                            StatBox(label: "File Size", value: formatFileSize(estimateSize(filteredLogs)))
                        }
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(FreshUI.Colors.background)

            Divider()
            
            // Action Buttons
            HStack {
                Text("\(getFilteredLogs().count) logs will be exported")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Export") {
                    exportLogs()
                }
                .buttonStyle(.borderedProminent)
                .disabled(getFilteredLogs().isEmpty || isExporting)
            }
            .padding()
        }
        .frame(width: 600, height: 650)
    }
    
    private func toggleLogType(_ type: String) {
        if type == "All" {
            if selectedLogTypes.contains("All") {
                selectedLogTypes.removeAll()
            } else {
                selectedLogTypes = ["All"]
            }
        } else {
            selectedLogTypes.remove("All")
            if selectedLogTypes.contains(type) {
                selectedLogTypes.remove(type)
            } else {
                selectedLogTypes.insert(type)
            }
        }
        
        // Ensure at least one type is selected
        if selectedLogTypes.isEmpty {
            selectedLogTypes = ["All"]
        }
    }
    
    private func getFilteredLogs() -> [PersistentDebugLogger.DebugLog] {
        var logs = debugLogger.logs
        
        // Apply type filter
        if !selectedLogTypes.contains("All") {
            logs = logs.filter { log in
                if selectedLogTypes.contains("Errors") && log.level == .error { return true }
                if selectedLogTypes.contains("Warnings") && log.level == .warning { return true }
                if selectedLogTypes.contains("Info") && log.level == .info { return true }
                if selectedLogTypes.contains("Success") && log.level == .success { return true }
                if selectedLogTypes.contains("Commands") && log.level == .command { return true }
                
                let message = log.message + (log.details ?? "")
                if selectedLogTypes.contains("yt-dlp") && message.contains("yt-dlp") { return true }
                if selectedLogTypes.contains("ffmpeg") && message.contains("ffmpeg") { return true }
                if selectedLogTypes.contains("App") && 
                   !message.contains("yt-dlp") && 
                   !message.contains("ffmpeg") { return true }
                
                return false
            }
        }
        
        // Apply time range filter
        if useTimeRange {
            logs = logs.filter { log in
                log.timestamp >= startDate && log.timestamp <= endDate
            }
        }
        
        return logs
    }
    
    private func estimateSize(_ logs: [PersistentDebugLogger.DebugLog]) -> Int64 {
        var size: Int64 = 0
        for log in logs {
            size += Int64(log.message.count)
            if includeDetails, let details = log.details {
                size += Int64(details.count)
            }
            size += 50 // Overhead for timestamp, level, etc.
        }
        return size
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func exportLogs() {
        isExporting = true
        let logs = getFilteredLogs()
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "fetcha-logs-\(Date().timeIntervalSince1970).\(exportFormat.fileExtension)"
        savePanel.allowedContentTypes = [exportFormat.contentType]
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    let content: String
                    
                    switch exportFormat {
                    case .text:
                        content = formatAsText(logs)
                    case .json:
                        content = formatAsJSON(logs)
                    case .csv:
                        content = formatAsCSV(logs)
                    }
                    
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    
                    // Show success notification
                    NSWorkspace.shared.open(url.deletingLastPathComponent())
                } catch {
                    PersistentDebugLogger.shared.log("Failed to export logs", level: .error, details: error.localizedDescription)
                }
            }
            isExporting = false
            dismiss()
        }
    }
    
    private func formatAsText(_ logs: [PersistentDebugLogger.DebugLog]) -> String {
        var output = """
        Fetcha Debug Logs Export
        ========================
        Exported: \(Date())
        Total Logs: \(logs.count)
        Time Range: \(useTimeRange ? "\(startDate) to \(endDate)" : "All time")
        
        ------------------------
        
        """
        
        for log in logs {
            let timestamp = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
            output += "[\(timestamp)] [\(log.level.rawValue.uppercased())] \(log.message)\n"
            
            if includeDetails, let details = log.details {
                output += "    Details: \(details)\n"
            }
        }
        
        return output
    }
    
    private func formatAsJSON(_ logs: [PersistentDebugLogger.DebugLog]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = [
            "metadata": [
                "exported": ISO8601DateFormatter().string(from: Date()),
                "count": logs.count,
                "timeRange": useTimeRange ? [
                    "start": ISO8601DateFormatter().string(from: startDate),
                    "end": ISO8601DateFormatter().string(from: endDate)
                ] : nil
            ],
            "logs": logs.map { log in
                var logDict: [String: Any] = [
                    "timestamp": ISO8601DateFormatter().string(from: log.timestamp),
                    "level": log.level.rawValue,
                    "message": log.message
                ]
                if includeDetails, let details = log.details {
                    logDict["details"] = details
                }
                return logDict
            }
        ] as [String : Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return "{}"
    }
    
    private func formatAsCSV(_ logs: [PersistentDebugLogger.DebugLog]) -> String {
        var output = "Timestamp,Level,Message"
        if includeDetails {
            output += ",Details"
        }
        output += "\n"
        
        for log in logs {
            let timestamp = ISO8601DateFormatter().string(from: log.timestamp)
            let message = log.message.replacingOccurrences(of: "\"", with: "\"\"")
            
            output += "\"\(timestamp)\",\"\(log.level.rawValue)\",\"\(message)\""
            
            if includeDetails {
                let details = (log.details ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                output += ",\"\(details)\""
            }
            output += "\n"
        }
        
        return output
    }
}

struct LogTypeToggle: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 14))
                
                Text(type)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}
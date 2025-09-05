import SwiftUI
import AppKit

struct VideoDetailsPanel: View {
    let item: QueueDownloadTask?
    let historyItem: DownloadHistory.DownloadRecord?
    @State private var thumbnailImage: NSImage?
    @State private var verboseOutput: String = ""
    @State private var downloadStartTime: Date?
    @State private var totalDownloadTime: String = ""
    
    init(item: QueueDownloadTask? = nil, historyItem: DownloadHistory.DownloadRecord? = nil) {
        self.item = item
        self.historyItem = historyItem
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Details")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if let item = item {
                // Show queue item details
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Thumbnail
                        if let thumbnail = item.thumbnail {
                            AsyncThumbnailView(url: thumbnail)
                                .id(thumbnail) // Force view recreation when thumbnail URL changes
                                .frame(height: 180)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            if let uploader = item.videoInfo.uploader {
                                Label(uploader, systemImage: "person.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if item.videoInfo.duration != nil {
                                Label(item.videoInfo.formattedDuration, systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Status section
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                HStack {
                                    Text(String(describing: item.status).capitalized)
                                        .fontWeight(.medium)
                                    Spacer()
                                    if item.status == .downloading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .progressViewStyle(CircularProgressViewStyle())
                                    }
                                }
                            } icon: {
                                Image(systemName: statusIcon(for: item.status))
                                    .foregroundColor(statusColor(for: item.status))
                            }
                            
                            if item.status == .failed {
                                Text(item.downloadStatus)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(3)
                            }
                            
                            if item.status == .downloading || item.status == .completed {
                                if item.progress > 0 {
                                    HStack {
                                        ProgressView(value: item.progress / 100.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                        Text("\(Int(item.progress))%")
                                            .font(.caption.monospacedDigit())
                                    }
                                }
                                
                                if !item.speed.isEmpty {
                                    Label(item.speed, systemImage: "speedometer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !item.eta.isEmpty {
                                    Label(item.eta, systemImage: "timer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Download info
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "URL", value: item.url)
                            
                            if let format = item.format {
                                DetailRow(label: "Format", value: "\(format.format_note ?? format.format_id)")
                                DetailRow(label: "Resolution", value: format.resolution ?? "Unknown")
                                if let codec = format.vcodec {
                                    DetailRow(label: "Codec", value: codec)
                                }
                            }
                            
                            DetailRow(label: "Location", value: item.downloadLocation.path)
                            
                            if let actualPath = item.actualFilePath {
                                DetailRow(label: "File", value: actualPath.lastPathComponent)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Actions
                        HStack(spacing: 12) {
                            if item.status == .completed {
                                // PERFORMANCE FIX: Use cached file path or simple check
                                let filePath: URL? = item.actualFilePath ?? item.downloadLocation
                                
                                if let path = filePath {
                                    Button(action: {
                                        // PERFORMANCE FIX: Simple async file check
                                        Task {
                                            if let actualPath = item.actualFilePath,
                                               FileManager.default.fileExists(atPath: actualPath.path) {
                                                await MainActor.run {
                                                    NSWorkspace.shared.activateFileViewerSelecting([actualPath])
                                                }
                                            } else {
                                                await MainActor.run {
                                                    NSWorkspace.shared.open(path)
                                                }
                                            }
                                        }
                                    }) {
                                        Label("Show in Finder", systemImage: "folder")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .controlSize(.small)
                                    
                                    Button(action: {
                                        // PERFORMANCE FIX: Simple open without complex file checking
                                        if let actualPath = item.actualFilePath {
                                            NSWorkspace.shared.open(actualPath)
                                        } else {
                                            NSWorkspace.shared.open(path)
                                        }
                                    }) {
                                        Label("Open", systemImage: "play.circle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .controlSize(.small)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Verbose output section
                        if item.status == .downloading || item.status == .failed {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Output")
                                    .font(.headline)
                                
                                ScrollView {
                                    Text(item.downloadStatus.isEmpty ? "No output available" : item.downloadStatus)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(4)
                                }
                                .frame(height: 150)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let historyItem = historyItem {
                // Show history item details
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Thumbnail
                        if let thumbnail = historyItem.thumbnail {
                            AsyncThumbnailView(url: thumbnail)
                                .id(thumbnail) // Force view recreation when thumbnail URL changes
                                .frame(height: 180)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(historyItem.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            if let uploader = historyItem.uploader {
                                Label(uploader, systemImage: "person.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            if let duration = historyItem.duration {
                                Label(formatDuration(Int(duration)), systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Download info
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "URL", value: historyItem.url)
                            DetailRow(label: "Downloaded", value: formatDate(historyItem.timestamp))
                            DetailRow(label: "Location", value: historyItem.downloadPath)
                            
                            // Show actual filename if available
                            if !historyItem.filename.isEmpty {
                                DetailRow(label: "File", value: historyItem.filename)
                            }
                            
                            if let fileSize = historyItem.fileSize {
                                DetailRow(label: "Size", value: formatFileSize(fileSize))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Actions
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Use the DownloadHistory method to find the actual file
                                    if let actualFileURL = DownloadHistory.shared.findActualFile(for: historyItem) {
                                        NSWorkspace.shared.activateFileViewerSelecting([actualFileURL])
                                        PersistentDebugLogger.shared.log("Showing file in Finder", level: .info, details: actualFileURL.lastPathComponent)
                                    } else {
                                        // Fall back to directory
                                        let url = URL(fileURLWithPath: historyItem.resolvedFilePath)
                                        if FileManager.default.fileExists(atPath: url.path) {
                                            NSWorkspace.shared.open(url)
                                        } else {
                                            NSWorkspace.shared.open(url.deletingLastPathComponent())
                                        }
                                    }
                                }) {
                                    Label("Show in Finder", systemImage: "folder")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                                
                                Button(action: {
                                    // Use the DownloadHistory method to find the actual file
                                    if let actualFileURL = DownloadHistory.shared.findActualFile(for: historyItem) {
                                        NSWorkspace.shared.open(actualFileURL)
                                        PersistentDebugLogger.shared.log("Opening file", level: .info, details: actualFileURL.lastPathComponent)
                                    } else {
                                        PersistentDebugLogger.shared.log(
                                            "File not found: \(historyItem.title)",
                                            level: .warning,
                                            details: "Path: \(historyItem.resolvedFilePath)"
                                        )
                                    }
                                }) {
                                    Label("Open", systemImage: "play.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                            }
                            
                            HStack(spacing: 12) {
                                // Open in Browser button
                                Button(action: {
                                    if let url = URL(string: historyItem.url) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Label("Open in Browser", systemImage: "safari")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                                
                                // Copy Source URL button
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(historyItem.url, forType: .string)
                                }) {
                                    Label("Copy Source", systemImage: "doc.on.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                // No selection
                ContentUnavailableView {
                    Label("No Selection", systemImage: "sidebar.right")
                } description: {
                    Text("Select an item to view details")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // Helper functions
    func statusIcon(for status: DownloadStatus) -> String {
        switch status {
        case .waiting: return "clock"
        case .downloading: return "arrow.down.circle"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    func statusColor(for status: DownloadStatus) -> Color {
        switch status {
        case .waiting: return .secondary
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .lineLimit(2)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct AsyncThumbnailView: View {
    let url: String
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, _ in
            // Reset image and reload when URL changes
            image = nil
            loadImage()
        }
    }
    
    func loadImage() {
        // Check if it's a local file path
        if url.hasPrefix("/") {
            // Local file path
            if let nsImage = NSImage(contentsOfFile: url) {
                DispatchQueue.main.async {
                    self.image = nsImage
                }
            }
        } else if let imageURL = URL(string: url) {
            // Remote URL
            URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                if let data = data, let nsImage = NSImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = nsImage
                    }
                }
            }.resume()
        }
    }
}
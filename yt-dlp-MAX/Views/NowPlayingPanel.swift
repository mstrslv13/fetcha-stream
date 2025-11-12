import SwiftUI
import AppKit

struct NowPlayingPanel: View {
    let item: QueueItem?
    let historyItem: DownloadHistory.DownloadRecord?
    @State private var isExpanded = false
    
    var currentItem: (title: String, url: String, thumbnail: String?, status: String, progress: Double)? {
        if let item = item {
            return (
                title: item.title,
                url: item.url,
                thumbnail: item.thumbnail,
                status: String(describing: item.status),
                progress: item.progress
            )
        } else if let historyItem = historyItem {
            return (
                title: historyItem.title,
                url: historyItem.url,
                thumbnail: historyItem.thumbnail,
                status: "completed", // History items are always completed
                progress: 100.0
            )
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let current = currentItem {
                ActiveDownloadView(
                    title: current.title,
                    url: current.url,
                    thumbnail: current.thumbnail,
                    status: current.status,
                    progress: current.progress,
                    item: item,
                    historyItem: historyItem
                )
            } else {
                EmptyNowPlayingView()
            }
        }
        .freshDetailsPanel()
        .background(FreshUI.Colors.background)
    }
}

// MARK: - Active Download View
struct ActiveDownloadView: View {
    let title: String
    let url: String
    let thumbnail: String?
    let status: String
    let progress: Double
    let item: QueueItem?
    let historyItem: DownloadHistory.DownloadRecord?
    
    @State private var showFullMetadata = false
    
    var statusColor: Color {
        switch status.lowercased() {
        case "completed": return FreshUI.Colors.success
        case "failed": return FreshUI.Colors.error
        case "downloading": return FreshUI.Colors.info
        case "paused": return FreshUI.Colors.warning
        default: return FreshUI.Colors.textSecondary
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Now Playing")
                        .font(FreshUI.Typography.headline)
                        .foregroundColor(FreshUI.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: FreshUI.Spacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(status.capitalized)
                            .font(FreshUI.Typography.caption)
                            .foregroundColor(FreshUI.Colors.textSecondary)
                    }
                    .padding(.horizontal, FreshUI.Spacing.sm)
                    .padding(.vertical, FreshUI.Spacing.xxs)
                    .background(FreshUI.Colors.surface)
                    .cornerRadius(FreshUI.Radii.full)
                }
                .padding(FreshUI.Spacing.lg)
                
                // Large Thumbnail
                ZStack {
                    if let thumbnailURL = thumbnail,
                       let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(FreshUI.Colors.surface)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(FreshUI.Colors.textTertiary)
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(FreshUI.Colors.surface)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                            )
                    }
                }
                .frame(maxHeight: 200)
                .cornerRadius(FreshUI.Radii.md)
                .padding(.horizontal, FreshUI.Spacing.lg)
                
                // Title and info
                VStack(alignment: .leading, spacing: FreshUI.Spacing.sm) {
                    Text(title)
                        .font(FreshUI.Typography.headline)
                        .foregroundColor(FreshUI.Colors.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let item = item {
                        if let uploader = item.videoInfo.uploader {
                            Text(uploader)
                                .font(FreshUI.Typography.body)
                                .foregroundColor(FreshUI.Colors.textSecondary)
                        }
                        
                        HStack(spacing: FreshUI.Spacing.md) {
                            if let duration = item.videoInfo.duration {
                                Label(formatDuration(Int(duration)), systemImage: "clock")
                                    .font(FreshUI.Typography.caption)
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                            }
                            
                            if let viewCount = item.videoInfo.view_count {
                                Label(formatNumber(viewCount), systemImage: "eye")
                                    .font(FreshUI.Typography.caption)
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                            }
                        }
                    }
                }
                .padding(FreshUI.Spacing.lg)
                
                // Progress Section
                if status.lowercased() == "downloading", let item = item {
                    DownloadProgressSection(item: item)
                        .padding(.horizontal, FreshUI.Spacing.lg)
                        .padding(.bottom, FreshUI.Spacing.lg)
                }
                
                // Action Buttons
                if let item = item {
                    ActionButtonsSection(item: item)
                        .padding(.horizontal, FreshUI.Spacing.lg)
                        .padding(.bottom, FreshUI.Spacing.lg)
                } else if let historyItem = historyItem {
                    HistoryActionButtons(historyItem: historyItem)
                        .padding(.horizontal, FreshUI.Spacing.lg)
                        .padding(.bottom, FreshUI.Spacing.lg)
                }
                
                // Metadata Section
                if showFullMetadata {
                    MetadataSection(item: item, historyItem: historyItem)
                        .padding(.horizontal, FreshUI.Spacing.lg)
                        .padding(.bottom, FreshUI.Spacing.lg)
                }
                
                Button(action: { showFullMetadata.toggle() }) {
                    HStack {
                        Text(showFullMetadata ? "Hide Details" : "Show Details")
                            .font(FreshUI.Typography.caption)
                        Image(systemName: showFullMetadata ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(FreshUI.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, FreshUI.Spacing.lg)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FreshUI.Colors.background)
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
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if number >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: Double(number) / 1_000_000)) ?? "")M"
        } else if number >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: Double(number) / 1_000)) ?? "")K"
        }
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Download Progress Section
struct DownloadProgressSection: View {
    @ObservedObject var item: QueueItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: FreshUI.Spacing.sm) {
            // Large progress bar
            VStack(alignment: .leading, spacing: FreshUI.Spacing.xs) {
                HStack {
                    Text("Download Progress")
                        .font(FreshUI.Typography.captionBold)
                        .foregroundColor(FreshUI.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(item.progress))%")
                        .font(FreshUI.Typography.caption.monospacedDigit())
                        .foregroundColor(FreshUI.Colors.textPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: FreshUI.Radii.xs)
                            .fill(FreshUI.Colors.surface)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: FreshUI.Radii.xs)
                            .fill(FreshUI.Colors.accentGreen)
                            .frame(width: geometry.size.width * CGFloat(item.progress) / 100, height: 8)
                            .animation(FreshUI.Animation.standard, value: item.progress)
                    }
                }
                .frame(height: 8)
            }
            
            // Speed and ETA
            HStack {
                if !item.speed.isEmpty {
                    Label(item.speed, systemImage: "speedometer")
                        .font(FreshUI.Typography.caption)
                        .foregroundColor(FreshUI.Colors.textTertiary)
                }
                
                if !item.eta.isEmpty {
                    Label(item.eta, systemImage: "timer")
                        .font(FreshUI.Typography.caption)
                        .foregroundColor(FreshUI.Colors.textTertiary)
                }
                
                Spacer()
            }
        }
        .padding(FreshUI.Spacing.md)
        .background(FreshUI.Colors.surface)
        .cornerRadius(FreshUI.Radii.md)
    }
}

// MARK: - Action Buttons
struct ActionButtonsSection: View {
    let item: QueueItem
    @EnvironmentObject private var downloadQueue: DownloadQueue
    
    var body: some View {
        HStack(spacing: FreshUI.Spacing.sm) {
            if item.status == .paused || item.status == .waiting {
                Button(action: { downloadQueue.resumeDownload(item) }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(FreshPrimaryButtonStyle())
            } else if item.status == .downloading {
                Button(action: { downloadQueue.pauseDownload(item) }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(FreshSecondaryButtonStyle())
            }
            
            if item.status == .failed {
                Button(action: { downloadQueue.retryDownload(item) }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(FreshPrimaryButtonStyle())
            }
            
            Button(action: { 
                downloadQueue.removeFromQueue(item)
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(FreshGhostButtonStyle())
        }
    }
}

// MARK: - History Action Buttons
struct HistoryActionButtons: View {
    let historyItem: DownloadHistory.DownloadRecord
    
    var body: some View {
        HStack(spacing: FreshUI.Spacing.sm) {
            Button(action: { showInFinder() }) {
                Label("Show in Finder", systemImage: "folder")
            }
            .buttonStyle(FreshPrimaryButtonStyle())
            .disabled(historyItem.actualFilePath == nil)
            
            Button(action: { copyURL() }) {
                Image(systemName: "link")
            }
            .buttonStyle(FreshGhostButtonStyle())
        }
    }
    
    func showInFinder() {
        guard let filePath = historyItem.actualFilePath else { return }
        NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "")
    }
    
    func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(historyItem.url, forType: .string)
    }
}

// MARK: - Metadata Section
struct MetadataSection: View {
    let item: QueueItem?
    let historyItem: DownloadHistory.DownloadRecord?
    
    var body: some View {
        VStack(alignment: .leading, spacing: FreshUI.Spacing.sm) {
            Text("Details")
                .font(FreshUI.Typography.captionBold)
                .foregroundColor(FreshUI.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: FreshUI.Spacing.xs) {
                if let item = item {
                    MetadataRow(label: "URL", value: item.url)
                    if let format = item.format {
                        MetadataRow(label: "Format", value: format.format_note ?? format.format_id)
                        if let fps = format.fps {
                            MetadataRow(label: "FPS", value: "\(fps)")
                        }
                    }
                    // File size not available on QueueItem
                } else if let historyItem = historyItem {
                    MetadataRow(label: "URL", value: historyItem.url)
                    MetadataRow(label: "Downloaded", value: formatDate(historyItem.timestamp))
                    if let filePath = historyItem.actualFilePath {
                        MetadataRow(label: "Location", value: URL(fileURLWithPath: filePath).lastPathComponent)
                    }
                    if historyItem.fileSize != nil {
                        MetadataRow(label: "Size", value: formatFileSize(historyItem.fileSize!))
                    }
                }
            }
        }
        .padding(FreshUI.Spacing.md)
        .background(FreshUI.Colors.surface)
        .cornerRadius(FreshUI.Radii.md)
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

// MARK: - Metadata Row
struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(FreshUI.Typography.caption)
                .foregroundColor(FreshUI.Colors.textTertiary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(FreshUI.Typography.caption)
                .foregroundColor(FreshUI.Colors.textSecondary)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

// MARK: - Empty State
struct EmptyNowPlayingView: View {
    var body: some View {
        VStack(spacing: FreshUI.Spacing.lg) {
            Spacer()
            
            Image(systemName: "play.square.stack")
                .font(.system(size: 64))
                .foregroundColor(FreshUI.Colors.textTertiary)
            
            Text("Nothing Playing")
                .font(FreshUI.Typography.headline)
                .foregroundColor(FreshUI.Colors.textSecondary)
            
            Text("Select a download from the queue or library")
                .font(FreshUI.Typography.caption)
                .foregroundColor(FreshUI.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FreshUI.Spacing.xl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
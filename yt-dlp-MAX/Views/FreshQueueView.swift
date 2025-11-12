import SwiftUI

struct FreshQueueView: View {
    @ObservedObject var queue: DownloadQueue
    @Binding var selectedItem: QueueDownloadTask?
    
    var body: some View {
        VStack(spacing: 0) {
            // Queue header with stats
            QueueHeaderBar(queue: queue)
            
            Divider()
                .background(FreshUI.Colors.divider)
            
            // Queue content
            if queue.items.isEmpty {
                EmptyQueueView()
            } else {
                ScrollView {
                    LazyVStack(spacing: FreshUI.Spacing.sm) {
                        ForEach(queue.items) { item in
                            FreshQueueCard(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                onSelect: { selectedItem = item },
                                queue: queue
                            )
                            .transition(.asymmetric(
                                insertion: .slide.combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(FreshUI.Spacing.md)
                }
                .scrollContentBackground(.hidden)
                .background(FreshUI.Colors.background)
            }
        }
        .background(FreshUI.Colors.background)
    }
}

// MARK: - Queue Header Bar
struct QueueHeaderBar: View {
    @ObservedObject var queue: DownloadQueue
    
    var downloadingCount: Int {
        queue.items.filter { $0.status == .downloading }.count
    }
    
    var completedCount: Int {
        queue.items.filter { $0.status == .completed }.count
    }
    
    var queuedCount: Int {
        queue.items.filter { $0.status == .waiting }.count
    }
    
    var body: some View {
        HStack {
            // Queue title and stats
            HStack(spacing: FreshUI.Spacing.md) {
                Text("Queue")
                    .font(FreshUI.Typography.headline)
                    .foregroundColor(FreshUI.Colors.textPrimary)
                
                if !queue.items.isEmpty {
                    HStack(spacing: FreshUI.Spacing.xs) {
                        if downloadingCount > 0 {
                            StatPill(
                                count: downloadingCount,
                                label: "Active",
                                color: FreshUI.Colors.accentGreen
                            )
                        }
                        if queuedCount > 0 {
                            StatPill(
                                count: queuedCount,
                                label: "Queued",
                                color: FreshUI.Colors.textSecondary
                            )
                        }
                        if completedCount > 0 {
                            StatPill(
                                count: completedCount,
                                label: "Done",
                                color: FreshUI.Colors.success
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Queue controls
            if !queue.items.isEmpty {
                HStack(spacing: FreshUI.Spacing.xs) {
                    Button(action: { queue.clearCompleted() }) {
                        Text("Clear Completed")
                            .font(FreshUI.Typography.caption)
                    }
                    .buttonStyle(FreshGhostButtonStyle())
                    
                    Button(action: { queue.togglePause() }) {
                        Image(systemName: queue.isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(queue.isPaused ? FreshUI.Colors.warning : FreshUI.Colors.textPrimary)
                    }
                    .buttonStyle(FreshSecondaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, FreshUI.Spacing.md)
        .padding(.vertical, FreshUI.Spacing.sm)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: FreshUI.Spacing.xxs) {
            Text("\(count)")
                .font(FreshUI.Typography.captionBold.monospacedDigit())
            Text(label)
                .font(FreshUI.Typography.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, FreshUI.Spacing.xs)
        .padding(.vertical, FreshUI.Spacing.xxxs)
        .background(color.opacity(0.15))
        .cornerRadius(FreshUI.Radii.full)
    }
}

// MARK: - Queue Card
struct FreshQueueCard: View {
    @ObservedObject var item: QueueItem
    let isSelected: Bool
    let onSelect: () -> Void
    let queue: DownloadQueue
    
    @State private var isHovered = false
    @State private var showActions = false
    
    var statusColor: Color {
        switch item.status {
        case .downloading: return FreshUI.Colors.accentGreen
        case .completed: return FreshUI.Colors.success
        case .failed: return FreshUI.Colors.error
        case .paused: return FreshUI.Colors.warning
        case .waiting: return FreshUI.Colors.textSecondary
        }
    }
    
    var statusIcon: String {
        switch item.status {
        case .downloading: return "arrow.down.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .waiting: return "clock.fill"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: FreshUI.Spacing.md) {
                // Thumbnail
                ZStack {
                    if let thumbnail = item.thumbnail,
                       let url = URL(string: thumbnail) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(FreshUI.Colors.surface)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.6)
                                        .tint(FreshUI.Colors.textTertiary)
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(FreshUI.Colors.surface)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                            )
                    }
                }
                .frame(width: FreshUI.Sizes.thumbnailMedium, height: FreshUI.Sizes.thumbnailMedium)
                .cornerRadius(FreshUI.Radii.sm)
                
                // Content
                VStack(alignment: .leading, spacing: FreshUI.Spacing.xs) {
                    // Title and status
                    HStack {
                        Text(item.title)
                            .font(FreshUI.Typography.bodyBold)
                            .foregroundColor(FreshUI.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Status icon
                        Image(systemName: statusIcon)
                            .font(.system(size: 14))
                            .foregroundColor(statusColor)
                    }
                    
                    // Metadata
                    HStack(spacing: FreshUI.Spacing.sm) {
                        if let uploader = item.videoInfo.uploader {
                            Text(uploader)
                                .font(FreshUI.Typography.caption)
                                .foregroundColor(FreshUI.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        
                        if let duration = item.videoInfo.duration {
                            Text("•")
                                .foregroundColor(FreshUI.Colors.textTertiary)
                            Text(formatDuration(duration))
                                .font(FreshUI.Typography.caption)
                                .foregroundColor(FreshUI.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Progress bar for downloading items
                    if item.status == .downloading {
                        VStack(alignment: .leading, spacing: FreshUI.Spacing.xxs) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(FreshUI.Colors.surface)
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(FreshUI.Colors.accentGreen)
                                        .frame(width: geometry.size.width * CGFloat(item.progress) / 100, height: 4)
                                        .animation(FreshUI.Animation.standard, value: item.progress)
                                }
                            }
                            .frame(height: 4)
                            
                            HStack(spacing: FreshUI.Spacing.sm) {
                                Text("\(Int(item.progress))%")
                                    .font(FreshUI.Typography.caption.monospacedDigit())
                                    .foregroundColor(FreshUI.Colors.accentGreen)
                                
                                if !item.speed.isEmpty {
                                    Text("•")
                                        .foregroundColor(FreshUI.Colors.textTertiary)
                                    Text(item.speed)
                                        .font(FreshUI.Typography.caption)
                                        .foregroundColor(FreshUI.Colors.textSecondary)
                                }
                                
                                if !item.eta.isEmpty {
                                    Text("•")
                                        .foregroundColor(FreshUI.Colors.textTertiary)
                                    Text(item.eta)
                                        .font(FreshUI.Typography.caption)
                                        .foregroundColor(FreshUI.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                    } else if item.status == .failed {
                        Text(item.downloadStatus)
                            .font(FreshUI.Typography.caption)
                            .foregroundColor(FreshUI.Colors.error)
                            .lineLimit(1)
                    }
                }
                
                // Action buttons (visible on hover)
                if isHovered || showActions {
                    HStack(spacing: FreshUI.Spacing.xs) {
                        if item.status == .paused || item.status == .waiting {
                            Button(action: { queue.resumeDownload(item) }) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(FreshGhostButtonStyle())
                        } else if item.status == .downloading {
                            Button(action: { queue.pauseDownload(item) }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(FreshGhostButtonStyle())
                        }
                        
                        if item.status == .failed {
                            Button(action: { queue.retryDownload(item) }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(FreshGhostButtonStyle())
                        }
                        
                        Button(action: { queue.removeFromQueue(item) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(FreshGhostButtonStyle())
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .padding(FreshUI.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FreshUI.Radii.md)
                    .fill(isSelected ? FreshUI.Colors.surfaceSelected :
                          (isHovered ? FreshUI.Colors.surfaceHover : FreshUI.Colors.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FreshUI.Radii.md)
                    .stroke(isSelected ? FreshUI.Colors.accentGreen.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .onHover { hovering in
                withAnimation(FreshUI.Animation.fast) {
                    isHovered = hovering
                    if !hovering {
                        showActions = false
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Empty Queue View
struct EmptyQueueView: View {
    var body: some View {
        VStack(spacing: FreshUI.Spacing.lg) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(FreshUI.Colors.textTertiary)
            
            Text("Your queue is empty")
                .font(FreshUI.Typography.headline)
                .foregroundColor(FreshUI.Colors.textSecondary)
            
            Text("Paste a URL above to start downloading")
                .font(FreshUI.Typography.body)
                .foregroundColor(FreshUI.Colors.textTertiary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

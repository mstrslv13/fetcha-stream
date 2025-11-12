import SwiftUI

struct FreshMediaBar: View {
    @ObservedObject var queue: DownloadQueue
    @ObservedObject var downloadHistory: DownloadHistory
    @State private var showVolumeSlider = false
    @State private var volume: Double = 0.7
    
    var activeDownload: QueueItem? {
        queue.items.first { $0.status == .downloading }
    }
    
    var completedToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return downloadHistory.history.filter { record in
            calendar.startOfDay(for: record.timestamp) == today
        }.count
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left section - Current download info
            HStack(spacing: FreshUI.Spacing.sm) {
                // Mini thumbnail
                if let download = activeDownload {
                    ZStack {
                        if let thumbnail = download.thumbnail,
                           let url = URL(string: thumbnail) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(FreshUI.Colors.surface)
                            }
                        } else {
                            Rectangle()
                                .fill(FreshUI.Colors.surface)
                                .overlay(
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.caption)
                                        .foregroundColor(FreshUI.Colors.textTertiary)
                                )
                        }
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(FreshUI.Radii.xs)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(download.title)
                            .font(FreshUI.Typography.caption)
                            .foregroundColor(FreshUI.Colors.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: FreshUI.Spacing.xs) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(FreshUI.Colors.accentGreen)
                            
                            Text("\(Int(download.progress))%")
                                .font(FreshUI.Typography.small.monospacedDigit())
                                .foregroundColor(FreshUI.Colors.textSecondary)
                            
                            if !download.speed.isEmpty {
                                Text("•")
                                    .foregroundColor(FreshUI.Colors.textTertiary)
                                Text(download.speed)
                                    .font(FreshUI.Typography.small)
                                    .foregroundColor(FreshUI.Colors.textSecondary)
                            }
                        }
                    }
                    .frame(width: 200, alignment: .leading)
                } else {
                    Image(systemName: "play.square.stack")
                        .font(.title3)
                        .foregroundColor(FreshUI.Colors.textTertiary)
                        .frame(width: 40, height: 40)
                    
                    Text("No active downloads")
                        .font(FreshUI.Typography.caption)
                        .foregroundColor(FreshUI.Colors.textSecondary)
                }
            }
            .padding(.horizontal, FreshUI.Spacing.md)
            .frame(minWidth: 280)
            
            Spacer()
            
            // Center section - Playback controls
            HStack(spacing: FreshUI.Spacing.md) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(FreshGhostButtonStyle())
                .disabled(true)
                
                Button(action: {
                    if queue.isPaused {
                        queue.togglePause()
                    } else if activeDownload != nil {
                        queue.togglePause()
                    }
                }) {
                    Image(systemName: queue.isPaused || activeDownload == nil ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(FreshUI.Colors.textPrimary)
                }
                .buttonStyle(.plain)
                .scaleEffect(activeDownload != nil ? 1.0 : 0.9)
                .animation(FreshUI.Animation.fast, value: activeDownload != nil)
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(FreshGhostButtonStyle())
                .disabled(true)
            }
            
            Spacer()
            
            // Right section - Stats and controls
            HStack(spacing: FreshUI.Spacing.md) {
                // Stats
                HStack(spacing: FreshUI.Spacing.xs) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(FreshUI.Colors.success)
                    Text("\(completedToday) today")
                        .font(FreshUI.Typography.caption)
                        .foregroundColor(FreshUI.Colors.textSecondary)
                }
                
                Divider()
                    .frame(height: 20)
                    .background(FreshUI.Colors.divider)
                
                // Queue status
                HStack(spacing: FreshUI.Spacing.xs) {
                    Circle()
                        .fill(queue.items.isEmpty ? FreshUI.Colors.textTertiary : 
                              (queue.isPaused ? FreshUI.Colors.warning : FreshUI.Colors.accentGreen))
                        .frame(width: 6, height: 6)
                    
                    Text("\(queue.items.count) in queue")
                        .font(FreshUI.Typography.caption)
                        .foregroundColor(FreshUI.Colors.textSecondary)
                }
                
                // Volume control (mock)
                Button(action: { showVolumeSlider.toggle() }) {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 14))
                }
                .buttonStyle(FreshGhostButtonStyle())
                .popover(isPresented: $showVolumeSlider, arrowEdge: .top) {
                    VolumeSlider(volume: $volume)
                }
            }
            .padding(.horizontal, FreshUI.Spacing.md)
            .frame(minWidth: 280)
        }
        .frame(height: 72)
        .background(FreshUI.Colors.surface)
        .overlay(
            Rectangle()
                .fill(FreshUI.Colors.divider)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    var volumeIcon: String {
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.fill"
        } else if volume < 0.66 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Volume Slider Popover
struct VolumeSlider: View {
    @Binding var volume: Double
    
    var body: some View {
        VStack(spacing: FreshUI.Spacing.sm) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 16))
                .foregroundColor(FreshUI.Colors.textSecondary)
            
            Slider(value: $volume, in: 0...1)
                .frame(width: 100)
                .tint(FreshUI.Colors.accentGreen)
            
            Text("\(Int(volume * 100))%")
                .font(FreshUI.Typography.caption.monospacedDigit())
                .foregroundColor(FreshUI.Colors.textSecondary)
        }
        .padding(FreshUI.Spacing.md)
        .background(FreshUI.Colors.surface)
        .cornerRadius(FreshUI.Radii.md)
    }
}
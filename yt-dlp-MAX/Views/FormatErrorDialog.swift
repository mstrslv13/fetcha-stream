import SwiftUI

struct FormatErrorDialog: View {
    let videoInfo: VideoInfo
    let availableFormats: [VideoFormat]
    @Binding var selectedFormat: VideoFormat?
    @Environment(\.dismiss) var dismiss
    
    @State private var filterType = "All"
    @State private var sortBy = "Quality"
    
    var filteredFormats: [VideoFormat] {
        let filtered: [VideoFormat]
        switch filterType {
        case "Video":
            filtered = availableFormats.filter { 
                $0.vcodec != nil && $0.vcodec != "none"
            }
        case "Audio":
            filtered = availableFormats.filter { 
                $0.acodec != nil && $0.acodec != "none" && 
                ($0.vcodec == nil || $0.vcodec == "none")
            }
        default:
            filtered = availableFormats
        }
        
        switch sortBy {
        case "Quality":
            return filtered.sorted { format1, format2 in
                let quality1 = format1.height ?? Int(format1.abr ?? 0)
                let quality2 = format2.height ?? Int(format2.abr ?? 0)
                return quality1 > quality2
            }
        case "Size":
            return filtered.sorted { format1, format2 in
                let size1 = format1.filesize ?? 0
                let size2 = format2.filesize ?? 0
                return size1 > size2
            }
        default:
            return filtered
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Format Not Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("The requested format is not available for this video. Please select an alternative format:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(videoInfo.title)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Filters
            HStack {
                Picker("Type", selection: $filterType) {
                    Text("All").tag("All")
                    Text("Video").tag("Video")
                    Text("Audio").tag("Audio")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Picker("Sort by", selection: $sortBy) {
                    Text("Quality").tag("Quality")
                    Text("Size").tag("Size")
                    Text("Format").tag("Format")
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            .padding()
            
            // Format list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(filteredFormats, id: \.format_id) { format in
                        FormatErrorRow(
                            format: format,
                            isSelected: selectedFormat?.format_id == format.format_id
                        ) {
                            selectedFormat = format
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Use Auto-Select") {
                    // Use the fallback selection logic
                    if let bestFormat = FormatType.bestVideo.getBestFormat(from: availableFormats) {
                        selectedFormat = bestFormat
                        dismiss()
                    }
                }
                
                Button("Select") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFormat == nil)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}

struct FormatErrorRow: View {
    let format: VideoFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var formatIcon: String {
        if format.vcodec != nil && format.vcodec != "none" {
            return "video"
        } else if format.acodec != nil && format.acodec != "none" {
            return "speaker.wave.2"
        } else {
            return "doc"
        }
    }
    
    var formatTypeLabel: String {
        if format.vcodec != nil && format.vcodec != "none" {
            if format.acodec != nil && format.acodec != "none" {
                return "Video+Audio"
            }
            return "Video Only"
        } else if format.acodec != nil && format.acodec != "none" {
            return "Audio Only"
        }
        return "Unknown"
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: formatIcon)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(format.qualityLabel)
                            .font(.system(size: 13, weight: .medium))
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(format.ext.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatTypeLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        if let vcodec = format.vcodec, vcodec != "none" {
                            Label(vcodec, systemImage: "video")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let acodec = format.acodec, acodec != "none" {
                            Label(acodec, systemImage: "speaker.wave.2")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let filesize = format.filesize {
                            Label(formatFileSize(filesize), systemImage: "doc")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let fps = format.fps {
                            Label("\(fps)fps", systemImage: "speedometer")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

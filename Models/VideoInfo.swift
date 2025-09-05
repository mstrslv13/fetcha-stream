import Foundation

struct VideoInfo: Codable {
    let title: String
    let uploader: String?
    let duration: Double?  // Changed to Double to handle float values
    let webpage_url: String
    var thumbnail: String?
    var formats: [VideoFormat]?  // Array of available formats
    
    // Additional fields that might come from different sources
    let description: String?
    let upload_date: String?
    let timestamp: Double?
    let view_count: Int?
    let like_count: Int?
    let channel_id: String?
    let uploader_id: String?
    let uploader_url: String?
    
    var formattedDuration: String {
        guard let duration = duration else {
            return "Unknown duration"
        }
        
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Helper computed property to get the best format automatically
    // This is like having a "chef's recommendation" on the menu
    var bestFormat: VideoFormat? {
        guard let formats = formats else { return nil }
        
        // First, try to find a format with both video and audio
        // These are complete files that "just work"
        let combinedFormats = formats.filter { format in
            format.vcodec != nil &&
            format.vcodec != "none" &&
            format.acodec != nil &&
            format.acodec != "none"
        }
        
        // Sort by height (quality) and return the best one
        return combinedFormats.max { first, second in
            (first.height ?? 0) < (second.height ?? 0)
        }
    }
    
    // Get formats grouped by quality for easy selection
    var formatsByQuality: [String: [VideoFormat]] {
        guard let formats = formats else { return [:] }
        
        var grouped: [String: [VideoFormat]] = [:]
        
        for format in formats {
            let quality = format.qualityLabel
            if grouped[quality] != nil {
                grouped[quality]?.append(format)
            } else {
                grouped[quality] = [format]
            }
        }
        
        return grouped
    }
}

// This represents a single downloadable format
// Think of each format as a different "version" of the same video
struct VideoFormat: Codable, Identifiable {
    let format_id: String        // yt-dlp's internal ID for this format
    let ext: String              // File extension (mp4, webm, etc.)
    let format_note: String?     // Human-readable note like "1080p"
    let filesize: Int?          // Size in bytes (if known)
    let filesize_approx: Int?   // Approximate size if exact not known
    let vcodec: String?         // Video codec (h264, vp9, etc.)
    let acodec: String?         // Audio codec (aac, opus, etc.)
    let height: Int?            // Video height in pixels
    let width: Int?             // Video width in pixels
    let fps: Double?            // Frames per second (can be fractional)
    let vbr: Double?            // Video bitrate
    let abr: Double?            // Audio bitrate
    let tbr: Double?            // Total bitrate
    let resolution: String?     // Resolution string like "1920x1080"
    let `protocol`: String?       // Protocol used (https, m3u8_native, etc.)
    let url: String?            // Direct URL to the format
    
    // Make it Identifiable so SwiftUI can display it in lists
    var id: String { format_id }
    
    // Create a user-friendly quality label
    var qualityLabel: String {
        if let height = height {
            return "\(height)p"
        } else if let format_note = format_note {
            return format_note
        } else if acodec != nil && vcodec == nil {
            return "Audio Only"
        } else {
            return "Unknown Quality"
        }
    }
    
    // Create a complete display name with all relevant info
    var displayName: String {
        var parts: [String] = []
        
        // Add quality
        parts.append(qualityLabel)
        
        // Add format
        parts.append("(\(ext))")
        
        // Add file size if known
        if let size = estimatedFileSize {
            parts.append(formatFileSize(size))
        }
        
        // Add codec info
        if let vcodec = vcodec, vcodec != "none" {
            parts.append(vcodec)
        }
        
        return parts.joined(separator: " • ")
    }
    
    // Helper to format bytes into human-readable sizes
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // Get the best size estimate available
    var estimatedFileSize: Int? {
        return filesize ?? filesize_approx
    }
    
    // Check if this format needs to be merged with audio
    var needsAudioMerge: Bool {
        // If there's video but no audio, we'll need to merge
        return vcodec != nil && vcodec != "none" &&
               (acodec == nil || acodec == "none")
    }
}

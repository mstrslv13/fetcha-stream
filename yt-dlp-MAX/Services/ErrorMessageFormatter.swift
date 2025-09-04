import Foundation

struct ErrorMessageFormatter {
    
    // Convert technical errors to user-friendly messages
    static func userFriendlyMessage(for error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        // Network-related errors
        if errorString.contains("connection") || errorString.contains("network") || errorString.contains("timed out") {
            return "Unable to connect. Please check your internet connection and try again."
        }
        
        // File/permission errors
        if errorString.contains("permission") || errorString.contains("denied") {
            return "Permission denied. Please check that the app has access to the selected folder."
        }
        
        if errorString.contains("no such file") || errorString.contains("not found") {
            return "The requested file or folder could not be found."
        }
        
        if errorString.contains("disk") || errorString.contains("space") {
            return "Not enough disk space. Please free up some space and try again."
        }
        
        // Download-specific errors
        if errorString.contains("json") || errorString.contains("parse") {
            return "Unable to process video information. The video may be unavailable or restricted."
        }
        
        if errorString.contains("playlist") {
            return "Unable to load playlist. It may be private or unavailable."
        }
        
        if errorString.contains("format") {
            return "The requested video format is not available. Please try a different quality setting."
        }
        
        if errorString.contains("ffmpeg") {
            return "Video processing failed. Please ensure ffmpeg is installed correctly."
        }
        
        if errorString.contains("yt-dlp") || errorString.contains("youtube-dl") {
            return "Download tool not found. Please check that yt-dlp is installed."
        }
        
        // Cookie/authentication errors
        if errorString.contains("cookie") || errorString.contains("auth") || errorString.contains("login") {
            return "Authentication required. Please check your browser cookies settings."
        }
        
        // Age restriction/private video
        if errorString.contains("age") || errorString.contains("restrict") || errorString.contains("private") {
            return "This video is restricted or private. Browser cookies may be required."
        }
        
        // Update errors
        if errorString.contains("update") {
            return "Update failed. Please try again later or update manually."
        }
        
        // Default message for unknown errors
        return "An unexpected error occurred. Please try again."
    }
    
    // Format error messages for specific operations
    static func formatDownloadError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Download failed. Please check the URL and try again."
        }
        return base
    }
    
    static func formatMetadataError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Unable to fetch video information. Please check the URL."
        }
        return base
    }
    
    static func formatPlaylistError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Unable to load playlist. It may be private or invalid."
        }
        return base
    }
    
    static func formatUpdateError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Update check failed. Please check your internet connection."
        }
        return base
    }
}
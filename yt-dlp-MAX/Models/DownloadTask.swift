//
//  DownloadTask.swift
//  yt-dlp-MAX
//
//  Created by mstrslv on 8/22/25.
//


import Foundation

// This represents a single download in progress
// We use a class (not struct) because we need to update it over time
// and have multiple parts of our app observe the same download
class DownloadTask: ObservableObject, Identifiable {
    let id = UUID()
    let videoInfo: VideoInfo
    let selectedFormat: VideoFormat
    let outputURL: URL
    
    // @Published means SwiftUI will automatically update any views
    // that display these properties when they change
    @Published var state: DownloadState = .pending
    @Published var progress: Double = 0.0  // 0.0 to 100.0
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var speed: String = ""
    @Published var eta: String = ""
    
    // Keep a reference to the process so we can cancel it
    var process: Process?
    
    init(videoInfo: VideoInfo, format: VideoFormat, outputURL: URL) {
        self.videoInfo = videoInfo
        self.selectedFormat = format
        self.outputURL = outputURL
    }
    
    // Cancel the download
    func cancel() {
        process?.terminate()
        state = .cancelled
    }
}

// All possible states a download can be in
enum DownloadState: Equatable {
    case pending           // Waiting to start
    case preparing        // Setting up the download
    case downloading      // Actually downloading
    case merging         // Combining video and audio (if needed)
    case completed       // All done!
    case failed(String)  // Something went wrong
    case cancelled       // User stopped it
    
    // Helper to check if the download is currently active
    var isActive: Bool {
        switch self {
        case .downloading, .preparing, .merging:
            return true
        default:
            return false
        }
    }
    
    // Human-readable description for the UI
    var description: String {
        switch self {
        case .pending:
            return "Waiting..."
        case .preparing:
            return "Preparing download..."
        case .downloading:
            return "Downloading..."
        case .merging:
            return "Processing video..."
        case .completed:
            return "Complete!"
        case .failed(let error):
            return "Failed: \(error)"
        case .cancelled:
            return "Cancelled"
        }
    }
}

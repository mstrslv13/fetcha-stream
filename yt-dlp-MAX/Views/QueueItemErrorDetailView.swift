//
//  QueueItemErrorDetailView.swift
//  yt-dlp-MAX
//
//  Error detail view for QueueItem model
//

import SwiftUI

struct QueueItemErrorDetailView: View {
    let item: QueueItem
    let queue: DownloadQueue
    @StateObject private var preferences = AppPreferences.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingFixOptions = false
    @State private var applyingFix = false
    
    // Error analysis
    var errorAnalysis: ErrorAnalysis {
        analyzeError(item.errorMessage ?? "Unknown error")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Download Error", systemImage: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Video Info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Video", systemImage: "play.rectangle")
                                .font(.headline)
                            
                            Text(item.title)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            
                            Text(item.url)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Error Details
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Error Details", systemImage: "xmark.circle")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            // User-friendly error message
                            Text(errorAnalysis.userMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if !errorAnalysis.suggestion.isEmpty {
                                Label(errorAnalysis.suggestion, systemImage: "lightbulb")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                            }
                            
                            // Technical details (collapsible)
                            DisclosureGroup("Technical Details") {
                                Text(item.errorMessage ?? "No detailed error message available")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Quick Fix Options
                    if !errorAnalysis.quickFixes.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Quick Fix Options", systemImage: "wrench.and.screwdriver")
                                    .font(.headline)
                                
                                ForEach(errorAnalysis.quickFixes, id: \.title) { fix in
                                    QuickFixItemButton(
                                        fix: fix,
                                        isApplying: $applyingFix,
                                        item: item,
                                        queue: queue,
                                        onDismiss: { dismiss() }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Manual Actions
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Actions", systemImage: "hand.tap")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Button("Retry Download") {
                                    queue.resumeDownload(item)
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Copy Error") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.errorMessage ?? "", forType: .string)
                                }
                                
                                Button("Remove from Queue") {
                                    queue.removeFromQueue(item)
                                    dismiss()
                                }
                                .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(FreshUI.Colors.background)
        }
        .frame(width: 550, height: 500)
    }
    
    struct ErrorAnalysis {
        let userMessage: String
        let suggestion: String
        let quickFixes: [QuickFix]
    }
    
    struct QuickFix {
        let title: String
        let description: String
        let icon: String
        let action: () async -> Void
    }
    
    func analyzeError(_ error: String) -> ErrorAnalysis {
        let lowerError = error.lowercased()
        var quickFixes: [QuickFix] = []
        let capturedQueue = self.queue
        
        // File already exists error
        if lowerError.contains("file") && lowerError.contains("exist") ||
           lowerError.contains("already downloaded") ||
           lowerError.contains("has already been recorded") ||
           lowerError.contains("destination:") && lowerError.contains("already exists") {
            
            quickFixes.append(QuickFix(
                title: "Enable Auto-Increment",
                description: "Automatically append numbers to filenames when duplicates exist",
                icon: "number.circle",
                action: {
                    await MainActor.run {
                        preferences.autoIncrementFilenames = true
                        capturedQueue.resumeDownload(item)
                    }
                }
            ))
            
            quickFixes.append(QuickFix(
                title: "Download to New Location",
                description: "Choose a different folder for this download",
                icon: "folder.badge.plus",
                action: {
                    await MainActor.run {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        panel.message = "Choose download location"
                        
                        if panel.runModal() == .OK, let url = panel.url {
                            // Update queue with new location for this item
                            item.customOutputPath = url.path
                            capturedQueue.resumeDownload(item)
                        }
                    }
                }
            ))
            
            return ErrorAnalysis(
                userMessage: "A file with the same name already exists in your download folder.",
                suggestion: "Enable auto-increment to automatically rename duplicate files, or choose a different download location.",
                quickFixes: quickFixes
            )
        }
        
        // Cookie/authentication errors
        if lowerError.contains("403") || lowerError.contains("forbidden") ||
           lowerError.contains("sign in") || lowerError.contains("cookie") ||
           lowerError.contains("private video") && lowerError.contains("sign in") {
            
            quickFixes.append(QuickFix(
                title: "Setup Browser Cookies",
                description: "Use your browser's login session",
                icon: "safari",
                action: {
                    await MainActor.run {
                        // Open preferences to cookie settings
                        NotificationCenter.default.post(name: NSNotification.Name("OpenPreferencesToCookies"), object: nil)
                    }
                }
            ))
            
            return ErrorAnalysis(
                userMessage: "This video requires authentication or has restricted access.",
                suggestion: "You may need to configure browser cookies to use your login session.",
                quickFixes: quickFixes
            )
        }
        
        // Format not available
        if lowerError.contains("format") && (lowerError.contains("not available") || lowerError.contains("unavailable")) {
            
            quickFixes.append(QuickFix(
                title: "Use Best Available Format",
                description: "Automatically select the best available format",
                icon: "sparkles",
                action: {
                    await MainActor.run {
                        item.format = nil // Reset to auto-select
                        capturedQueue.resumeDownload(item)
                    }
                }
            ))
            
            return ErrorAnalysis(
                userMessage: "The selected video format is not available.",
                suggestion: "Try using the best available format instead.",
                quickFixes: quickFixes
            )
        }
        
        // Network errors
        if lowerError.contains("connection") || lowerError.contains("timeout") ||
           lowerError.contains("network") || lowerError.contains("unable to download") ||
           lowerError.contains("urlopen error") {
            
            quickFixes.append(QuickFix(
                title: "Retry with Lower Quality",
                description: "Try downloading a smaller file size",
                icon: "arrow.down.circle",
                action: {
                    await MainActor.run {
                        // Find a lower quality format
                        if let formats = item.videoInfo.formats {
                            let sortedFormats = formats.sorted { ($0.height ?? 0) < ($1.height ?? 0) }
                            if let lowerFormat = sortedFormats.first(where: { ($0.height ?? 0) <= 720 }) {
                                item.format = lowerFormat
                            }
                        }
                        capturedQueue.resumeDownload(item)
                    }
                }
            ))
            
            return ErrorAnalysis(
                userMessage: "The download failed due to a network issue.",
                suggestion: "Check your internet connection and try again, or try downloading a lower quality version.",
                quickFixes: quickFixes
            )
        }
        
        // Age restriction
        if lowerError.contains("age") || lowerError.contains("inappropriate") ||
           lowerError.contains("confirm your age") {
            
            quickFixes.append(QuickFix(
                title: "Configure Cookies",
                description: "Use browser cookies with age verification",
                icon: "person.crop.circle.badge.checkmark",
                action: {
                    await MainActor.run {
                        NotificationCenter.default.post(name: NSNotification.Name("OpenPreferencesToCookies"), object: nil)
                    }
                }
            ))
            
            return ErrorAnalysis(
                userMessage: "This video is age-restricted and requires verification.",
                suggestion: "Configure browser cookies from a logged-in session with age verification.",
                quickFixes: quickFixes
            )
        }
        
        // Private/deleted video
        if lowerError.contains("private") || lowerError.contains("deleted") ||
           lowerError.contains("unavailable") || lowerError.contains("404") ||
           lowerError.contains("video not available") {
            
            return ErrorAnalysis(
                userMessage: "This video is private, deleted, or no longer available.",
                suggestion: "The video cannot be downloaded. It may have been removed by the uploader.",
                quickFixes: []
            )
        }
        
        // Generic/unknown error
        return ErrorAnalysis(
            userMessage: "The download failed due to an unexpected error.",
            suggestion: "Try retrying the download or check the technical details for more information.",
            quickFixes: quickFixes
        )
    }
}

struct QuickFixItemButton: View {
    let fix: QueueItemErrorDetailView.QuickFix
    @Binding var isApplying: Bool
    let item: QueueItem
    let queue: DownloadQueue
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: {
            isApplying = true
            Task {
                await fix.action()
                await MainActor.run {
                    isApplying = false
                    onDismiss()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: fix.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fix.title)
                        .font(.system(size: 13, weight: .medium))
                    
                    Text(fix.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isApplying {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
    }
}

// Extension to QueueItem for custom output path
extension QueueItem {
    private static let customOutputPathKey = UnsafeRawPointer(UnsafePointer<UInt8>(bitPattern: "customOutputPath".hashValue)!)
    
    var customOutputPath: String? {
        get {
            objc_getAssociatedObject(self, Self.customOutputPathKey) as? String
        }
        set {
            objc_setAssociatedObject(self, Self.customOutputPathKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
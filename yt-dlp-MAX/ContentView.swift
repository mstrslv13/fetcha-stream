import SwiftUI
import UniformTypeIdentifiers
import AppKit
import Combine

struct ContentView: View {
    @State private var urlString = ""
    @State private var statusMessage = "Paste a video URL to start downloading"
    @State private var isLoading = false
    @State private var videoInfo: VideoInfo?
    @State private var selectedFormat: VideoFormat?
    @State private var showingDebugView = false
    @State private var showingPreferences = false
    @State private var lastClipboard = ""
    @State private var selectedQueueItem: QueueDownloadTask?
    @State private var showingPlaylistConfirmation = false
    @State private var detectedPlaylistInfo: PlaylistConfirmationView.PlaylistInfo?
    @State private var showHistoryPanel = false
    @State private var showDetailsPanel = true
    @State private var historyPanelWidth: CGFloat = 300
    @State private var preferencesWindow: NSWindow?
    @StateObject private var downloadQueue = DownloadQueue()
    @StateObject private var preferences = AppPreferences.shared
    @StateObject private var downloadHistory = DownloadHistory.shared
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    
    private let ytdlpService = YTDLPService()
    private let pasteboardTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            // History/Debug panel on the left with smoother animation
            if showHistoryPanel {
                FileHistoryPanel()
                    .frame(width: historyPanelWidth)
                    .transition(.asymmetric(
                        insertion: .push(from: .leading),
                        removal: .push(from: .trailing)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showHistoryPanel)
                
                // Resizable divider
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 4)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = historyPanelWidth + value.translation.width
                                historyPanelWidth = min(max(newWidth, 250), 500)
                            }
                    )
                
                Divider()
            }
            
            // Toggle button for history panel
            VStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showHistoryPanel.toggle()
                        // Resize window to accommodate panel
                        resizeWindowForPanels(showHistory: showHistoryPanel, showDetails: showDetailsPanel)
                    }
                }) {
                    Image(systemName: showHistoryPanel ? "sidebar.left.filled" : "sidebar.left")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Toggle History Panel")
                .accessibilityLabel("Toggle History Panel")
                .accessibilityHint("Shows or hides the download history panel")
                .padding(.leading, 4)
                Spacer()
            }
            
            // Main column with URL input and queue
            VStack(spacing: 0) {
                // URL input field
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Paste video URL here...", text: $urlString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                handleURLSubmit()
                            }
                            .onChange(of: urlString) { oldValue, newValue in
                                if preferences.autoAddToQueue && isValidURL(newValue) {
                                    handleURLSubmit()
                                }
                            }
                        
                        Button(action: {
                            pasteAndProcess()
                        }) {
                            Image(systemName: "doc.on.clipboard.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Paste and add to queue")
                        .accessibilityLabel("Paste URL")
                        .accessibilityHint("Paste URL from clipboard and add to queue")
                        
                        if !preferences.autoAddToQueue {
                            Button("Add to Queue") {
                                handleURLSubmit()
                            }
                            .accessibilityLabel("Add to Queue")
                            .accessibilityHint("Add the entered URL to the download queue")
                            .disabled(urlString.isEmpty || isLoading)
                        }
                        
                        Button(action: {
                            showingPreferences = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                        .buttonStyle(.plain)
                        .help("Preferences")
                        .accessibilityLabel("Open Preferences")
                        .accessibilityHint("Opens the application preferences window")
                    }
                    
                    // Enhanced Progress Bar
                    if !downloadQueue.items.isEmpty {
                        EnhancedProgressBar(queue: downloadQueue)
                            .frame(height: 24)
                            .padding(.vertical, 4)
                    }
                    
                    // Status message
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Download queue
                EnhancedQueueView(
                    queue: downloadQueue,
                    selectedItem: $selectedQueueItem
                )
            }
            .frame(minWidth: 400)
            
            // Toggle button for details panel
            VStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showDetailsPanel.toggle()
                        // Resize window to accommodate panel
                        resizeWindowForPanels(showHistory: showHistoryPanel, showDetails: showDetailsPanel)
                    }
                }) {
                    Image(systemName: showDetailsPanel ? "sidebar.right.filled" : "sidebar.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Toggle Details Panel")
                .accessibilityLabel("Toggle Details Panel")
                .accessibilityHint("Shows or hides the video details panel")
                .padding(.trailing, 4)
                Spacer()
            }
            
            // Details panel on the right with smoother animation
            if showDetailsPanel {
                Divider()
                
                VideoDetailsPanel(item: selectedQueueItem)
                    .frame(width: 350)
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing),
                        removal: .push(from: .leading)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDetailsPanel)
            }
        }
        .frame(minWidth: {
            var width = 450  // Base width for main content
            if showHistoryPanel { width += Int(historyPanelWidth) }
            if showDetailsPanel { width += 350 }
            return CGFloat(width)
        }(), minHeight: 600)
        .onReceive(pasteboardTimer) { _ in
            checkClipboardForURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            // Auto-adjust panels when window is resized
            withAnimation(.easeInOut(duration: 0.2)) {
                autoAdjustPanelWidth()
            }
        }
        .onChange(of: showingDebugView) { oldValue, newValue in
            if newValue {
                openDebugWindow()
                showingDebugView = false
            }
        }
        .onChange(of: showingPreferences) { oldValue, newValue in
            if newValue {
                openPreferencesWindow()
                showingPreferences = false
            }
        }
        .onAppear {
            statusMessage = preferences.autoAddToQueue ? 
                "Auto-queue enabled: Paste any URL to start downloading" : 
                "Paste a video URL to get started"
        }
        .sheet(isPresented: $showingPlaylistConfirmation) {
            if let playlistInfo = detectedPlaylistInfo {
                PlaylistConfirmationView(
                    playlistInfo: playlistInfo,
                    onConfirm: { action in
                        showingPlaylistConfirmation = false
                        handlePlaylistAction(action, url: urlString, playlistInfo: playlistInfo)
                    },
                    onCancel: {
                        showingPlaylistConfirmation = false
                        isLoading = false
                        statusMessage = "Playlist cancelled"
                        urlString = ""
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handlePlaylistAction(_ action: PlaylistConfirmationView.PlaylistAction, url: String, playlistInfo: PlaylistConfirmationView.PlaylistInfo) {
        switch action {
        case .downloadAll:
            addPlaylistToQueue(url: url, downloadAll: true)
        case .downloadRange(let start, let end):
            addPlaylistToQueue(url: url, downloadAll: true, range: (start: start, end: end))
        case .downloadSingle:
            addPlaylistToQueue(url: url, downloadAll: false)
        case .cancel:
            statusMessage = "Cancelled"
            urlString = ""
        }
    }
    
    private func checkClipboardForURL() {
        guard preferences.autoAddToQueue else { return }
        
        if let clipboard = NSPasteboard.general.string(forType: .string),
           clipboard != lastClipboard,
           isValidURL(clipboard) {
            lastClipboard = clipboard
            let url = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !downloadQueue.items.contains(where: { $0.url == url }) {
                urlString = ""
                if preferences.skipMetadataFetch {
                    quickAddToQueueWithURL(url)
                } else {
                    fetchAndAutoAddWithURL(url)
                }
            }
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let patterns = [
            "^https?://",
            "^(www\\.)?youtube\\.com",
            "^(www\\.)?youtu\\.be",
            "^(www\\.)?vimeo\\.com",
            "^(www\\.)?twitter\\.com",
            "^(www\\.)?x\\.com"
        ]
        
        return patterns.contains { pattern in
            trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
    
    private func handleURLSubmit() {
        guard !urlString.isEmpty else { return }
        
        let url = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidURL(url) else {
            statusMessage = "Invalid URL format"
            return
        }
        
        if downloadQueue.items.contains(where: { $0.url == url }) {
            statusMessage = "URL already in queue"
            return
        }
        
        isLoading = true
        statusMessage = "Checking URL..."
        
        Task {
            do {
                // First check if it's a playlist
                let playlistCheck = try await ytdlpService.checkForPlaylist(urlString: url)
                
                if playlistCheck.isPlaylist {
                    // Handle playlist based on preference
                    await MainActor.run {
                        handlePlaylistURL(url: url, videoCount: playlistCheck.count)
                    }
                } else {
                    // Handle single video as before
                    let info = try await ytdlpService.fetchMetadata(for: url)
                    await MainActor.run {
                        self.videoInfo = info
                        self.isLoading = false
                        
                        if preferences.autoAddToQueue || preferences.skipMetadataFetch {
                            downloadQueue.addToQueue(url: url, format: info.bestFormat, videoInfo: info)
                            statusMessage = "Added to queue: \(info.title)"
                            urlString = ""
                            videoInfo = nil
                        } else {
                            statusMessage = "Select format and quality"
                            selectedFormat = info.bestFormat
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = ErrorMessageFormatter.formatMetadataError(error)
                }
            }
        }
    }
    
    private func handlePlaylistURL(url: String, videoCount: Int?) {
        statusMessage = "Playlist detected (\(videoCount ?? 0) videos)"
        
        // Check user preference for playlist handling
        switch preferences.playlistHandling {
        case "ask":
            // Show confirmation dialog
            isLoading = true
            Task {
                do {
                    let playlistInfo = try await ytdlpService.fetchPlaylistInfo(
                        urlString: url,
                        limit: min(preferences.playlistLimit, 100)
                    )
                    await MainActor.run {
                        self.detectedPlaylistInfo = playlistInfo
                        self.showingPlaylistConfirmation = true
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.statusMessage = ErrorMessageFormatter.formatPlaylistError(error)
                    }
                }
            }
            
        case "all":
            // Automatically download all videos
            addPlaylistToQueue(url: url, downloadAll: true)
            
        case "single":
            // Just download the first video
            addPlaylistToQueue(url: url, downloadAll: false)
            
        default:
            statusMessage = "Unknown playlist handling preference"
        }
    }
    
    private func addPlaylistToQueue(url: String, downloadAll: Bool, range: (start: Int, end: Int)? = nil) {
        isLoading = true
        statusMessage = downloadAll ? "Adding playlist to queue..." : "Adding first video..."
        
        Task {
            do {
                let playlistInfo = try await ytdlpService.fetchPlaylistInfo(
                    urlString: url,
                    limit: downloadAll ? preferences.playlistLimit : 1
                )
                
                await MainActor.run {
                    var videosToAdd = playlistInfo.videos
                    
                    // Apply range if specified
                    if let range = range {
                        let startIdx = max(0, range.start - 1)
                        let endIdx = range.end > 0 ? min(range.end, videosToAdd.count) : videosToAdd.count
                        videosToAdd = Array(videosToAdd[startIdx..<endIdx])
                    }
                    
                    // Apply reverse order if needed
                    if preferences.reversePlaylist {
                        videosToAdd.reverse()
                    }
                    
                    // Filter out duplicates if needed
                    if preferences.skipDuplicates {
                        videosToAdd = videosToAdd.filter { video in
                            !downloadHistory.hasDownloaded(url: video.webpage_url)
                        }
                    }
                    
                    // Add videos to queue
                    var addedCount = 0
                    for video in videosToAdd {
                        // Fetch full metadata for each video
                        Task {
                            do {
                                let fullInfo = try await ytdlpService.fetchMetadata(for: video.webpage_url)
                                await MainActor.run {
                                    downloadQueue.addToQueue(
                                        url: video.webpage_url,
                                        format: fullInfo.bestFormat,
                                        videoInfo: fullInfo
                                    )
                                }
                            } catch {
                                print("Failed to fetch metadata for \(video.title): \(error)")
                            }
                        }
                        addedCount += 1
                    }
                    
                    statusMessage = "Added \(addedCount) videos to queue"
                    urlString = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = ErrorMessageFormatter.formatPlaylistError(error)
                }
            }
        }
    }
    
    private func fetchAndAutoAddWithURL(_ url: String) {
        isLoading = true
        statusMessage = "Auto-adding from clipboard..."
        
        Task {
            do {
                let info = try await ytdlpService.fetchMetadata(for: url)
                await MainActor.run {
                    downloadQueue.addToQueue(url: url, format: info.bestFormat, videoInfo: info)
                    statusMessage = "Auto-added: \(info.title)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = ErrorMessageFormatter.formatDownloadError(error)
                    isLoading = false
                }
            }
        }
    }
    
    private func autoAdjustPanelWidth() {
        // Get current window 
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Calculate required width
        var requiredWidth: CGFloat = 450  // Base width for main content
        if showHistoryPanel { requiredWidth += historyPanelWidth }
        if showDetailsPanel { requiredWidth += 350 }
        
        // If window is too small, resize it to fit
        if window.frame.width < requiredWidth {
            var newFrame = window.frame
            newFrame.size.width = requiredWidth
            // Adjust origin to keep window centered
            newFrame.origin.x -= (requiredWidth - window.frame.width) / 2
            window.setFrame(newFrame, display: true, animate: true)
        }
        
        // Adjust panel widths based on new window size
        let windowWidth = window.frame.width
        if windowWidth < 1200 {
            // Smaller window - use minimum panel widths
            historyPanelWidth = 250
        } else {
            // Larger window - proportional panel widths
            historyPanelWidth = min(350, windowWidth * 0.25)
        }
    }
    
    private func resizeWindowForPanels(showHistory: Bool, showDetails: Bool) {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Calculate new required width
        var requiredWidth: CGFloat = 450  // Base width
        if showHistory { requiredWidth += historyPanelWidth }
        if showDetails { requiredWidth += 350 }
        
        // Animate window resize
        var newFrame = window.frame
        let widthDiff = requiredWidth - window.frame.width
        newFrame.size.width = requiredWidth
        
        // Adjust position to keep window reasonably centered
        if showHistory && !showDetails {
            // Opening left panel - expand left
            newFrame.origin.x -= widthDiff
        } else if !showHistory && showDetails {
            // Opening right panel - keep position
        } else {
            // Opening both or changing - center expansion
            newFrame.origin.x -= widthDiff / 2
        }
        
        window.setFrame(newFrame, display: true, animate: true)
    }
    
    private func quickAddToQueueWithURL(_ url: String) {
        let placeholderInfo = VideoInfo(
            title: "Loading...",
            uploader: nil,
            duration: nil,
            webpage_url: url,
            thumbnail: nil,
            formats: nil,
            description: nil,
            upload_date: nil,
            timestamp: nil,
            view_count: nil,
            like_count: nil,
            channel_id: nil,
            uploader_id: nil,
            uploader_url: nil
        )
        
        downloadQueue.addToQueue(url: url, format: nil, videoInfo: placeholderInfo)
        statusMessage = "Quick-added to queue (metadata loading...)"
        
        Task {
            if downloadQueue.items.contains(where: { $0.url == url }) {
                if let _ = try? await ytdlpService.fetchMetadata(for: url) {
                    await MainActor.run {
                        // FUTURE: Phase 5 - Update queue item with fetched metadata
                        // This would need to be implemented in DownloadQueue
                        // Would update the placeholder "Loading..." with real title
                        // Integration point for background metadata updates
                    }
                }
            }
        }
    }
    
    private func pasteAndProcess() {
        if let clipboard = NSPasteboard.general.string(forType: .string) {
            urlString = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            handleURLSubmit()
        } else {
            statusMessage = "No URL found in clipboard"
        }
    }
    
    private func addToQueue() {
        guard let info = videoInfo else { return }
        let format = selectedFormat ?? info.bestFormat
        
        downloadQueue.addToQueue(url: info.webpage_url, format: format, videoInfo: info)
        statusMessage = "Added to queue: \(info.title)"
        urlString = ""
        videoInfo = nil
        selectedFormat = nil
    }
    
    private func openDebugWindow() {
        let debugView = DebugView()
        let hostingController = NSHostingController(rootView: debugView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Debug Console"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask = [.titled, .closable, .resizable]
        window.makeKeyAndOrderFront(nil)
    }
    
    private func openPreferencesWindow() {
        // Check if preferences window already exists and is visible
        if let existingWindow = preferencesWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new preferences window
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 700, height: 500))
        window.styleMask = [.titled, .closable]
        window.makeKeyAndOrderFront(nil)
        
        // Store reference to window
        preferencesWindow = window
        
        // Clean up reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            self.preferencesWindow = nil
        }
    }
}

// Enhanced Progress Bar with better animation
struct EnhancedProgressBar: View {
    @ObservedObject var queue: DownloadQueue
    
    var completedCount: Int {
        queue.items.filter { $0.status == .completed }.count
    }
    
    var totalCount: Int {
        queue.items.count
    }
    
    var downloadingCount: Int {
        queue.items.filter { $0.status == .downloading }.count
    }
    
    var overallProgress: Double {
        guard totalCount > 0 else { return 0 }
        
        var totalProgress = Double(completedCount * 100)
        
        // Add partial progress from downloading items
        for item in queue.items where item.status == .downloading {
            totalProgress += item.progress
        }
        
        return totalProgress / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Large progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                    
                    // Progress fill with animation
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(overallProgress) / 100)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: overallProgress)
                    
                    // Shimmer effect for active downloads
                    if downloadingCount > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(overallProgress) / 100)
                            .offset(x: geometry.size.width * CGFloat(overallProgress) / 100 - 50)
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: downloadingCount
                            )
                    }
                }
            }
            
            // Stats text
            HStack(spacing: 12) {
                if downloadingCount > 0 {
                    Label("\(downloadingCount) downloading", systemImage: "arrow.down.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                }
                
                Label("\(completedCount) of \(totalCount)", systemImage: "checkmark.circle")
                    .foregroundColor(completedCount == totalCount ? .green : .secondary)
                    .font(.caption)
                
                Spacer()
                
                Text("\(Int(overallProgress))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
    }
}
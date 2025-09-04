# Phase 2: Queue System & File Management - Day 3 of Your PTO Sprint
## Building a Download Manager That Actually Manages

### Today's Mission

By the end of Day 3, you'll have transformed your single-download tool into a proper queue-based download manager. Users will be able to add multiple videos, watch them download in sequence, and have intelligent file naming that doesn't require a PhD in yt-dlp syntax. This is the day your app becomes genuinely useful for real-world scenarios.

Think of this like upgrading from a food truck to a restaurant. Yesterday you proved you could cook one dish at a time. Today we're adding the ability to handle multiple orders, keep track of what's in progress, and ensure everything gets delivered to the right table. We're also going to nail that cookie integration you identified as your secret weapon.

### Morning: Building the Queue Foundation (3-4 hours)

Let's start by creating a proper data model for downloads. In Swift, we'll use classes for objects that need to be shared and modified (like our download queue) and structs for simple data containers.

**Creating the Download Model:**

Create a new file called `Models/Download.swift`:

```swift
import Foundation
import SwiftUI

// This enum represents all possible states a download can be in
// It's like a state machine - a download moves through these states
enum DownloadState: Equatable {
    case pending                           // Waiting in queue
    case fetchingMetadata                  // Getting video info
    case downloading(progress: Double)     // Actively downloading (with progress 0-100)
    case processing                        // Post-processing (like converting formats)
    case completed(fileURL: URL)          // Done, here's where the file is
    case failed(error: String)            // Something went wrong
    case cancelled                        // User stopped it
    
    // Computed property to check if this download needs attention
    var isActive: Bool {
        switch self {
        case .downloading, .processing, .fetchingMetadata:
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
        case .fetchingMetadata:
            return "Getting video info..."
        case .downloading(let progress):
            return String(format: "Downloading: %.1f%%", progress)
        case .processing:
            return "Processing..."
        case .completed:
            return "Complete"
        case .failed(let error):
            return "Failed: \(error)"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    // Color coding for visual feedback
    var statusColor: Color {
        switch self {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        case .downloading, .processing, .fetchingMetadata:
            return .blue
        case .pending:
            return .gray
        }
    }
}

// This class represents a single download
// It's a class (not struct) because we need to modify it and observe changes
class Download: ObservableObject, Identifiable {
    let id = UUID()  // Unique identifier
    let url: String
    let videoInfo: VideoInfo
    let selectedFormat: VideoFormat
    
    @Published var state: DownloadState = .pending
    @Published var customFileName: String
    @Published var outputDirectory: URL
    
    // Store the process so we can cancel it if needed
    var process: Process?
    
    init(url: String, videoInfo: VideoInfo, format: VideoFormat, outputDirectory: URL) {
        self.url = url
        self.videoInfo = videoInfo
        self.selectedFormat = format
        self.outputDirectory = outputDirectory
        
        // Generate initial filename from video title
        self.customFileName = Self.sanitizeFileName(videoInfo.title)
    }
    
    // Clean up filename for filesystem compatibility
    static func sanitizeFileName(_ name: String) -> String {
        // Remove characters that cause problems in filenames
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = name.components(separatedBy: invalidCharacters).joined(separator: "_")
        
        // Trim whitespace and limit length
        let trimmed = cleaned.trimmingCharacters(in: .whitespaces)
        let maxLength = 200  // Keep filenames reasonable
        
        if trimmed.count > maxLength {
            let index = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
            return String(trimmed[..<index])
        }
        
        return trimmed.isEmpty ? "download" : trimmed
    }
    
    // Get the final output path
    var outputPath: URL {
        outputDirectory
            .appendingPathComponent(customFileName)
            .appendingPathExtension(selectedFormat.ext)
    }
    
    // Cancel this download
    func cancel() {
        process?.terminate()
        state = .cancelled
    }
}
```

**Creating the Queue Manager:**

Now we need a central manager for our queue. Create `Services/QueueManager.swift`:

```swift
import Foundation
import SwiftUI

// This is our main queue manager - it coordinates all downloads
// We use @MainActor to ensure all UI updates happen on the main thread
@MainActor
class QueueManager: ObservableObject {
    // Make it a singleton so there's only one queue in the app
    static let shared = QueueManager()
    
    // Published properties automatically update the UI when they change
    @Published var downloads: [Download] = []
    @Published var isProcessing = false
    @Published var currentDownload: Download?
    
    // Settings
    @Published var simultaneousDownloads = 1  // How many downloads at once
    @Published var defaultOutputDirectory: URL
    
    private let ytdlpService = YTDLPService()
    private let cookieManager = CookieManager()
    
    private init() {
        // Set default download location to user's Downloads folder
        self.defaultOutputDirectory = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("yt-dlp-MAX")
        
        // Create our download folder if it doesn't exist
        try? FileManager.default.createDirectory(
            at: defaultOutputDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // Add a URL to the queue
    func addToQueue(url: String, useCookies: Bool = false) async {
        // First, check if this URL is already in the queue
        if downloads.contains(where: { $0.url == url }) {
            print("URL already in queue: \(url)")
            return
        }
        
        do {
            // Fetch metadata
            let videoInfo = try await ytdlpService.fetchMetadata(for: url)
            
            // Pick the best format automatically (user can change later)
            guard let format = videoInfo.bestFormat else {
                throw YTDLPError.noFormatAvailable
            }
            
            // Create the download object
            let download = Download(
                url: url,
                videoInfo: videoInfo,
                format: format,
                outputDirectory: defaultOutputDirectory
            )
            
            // Add to queue
            downloads.append(download)
            
            // Start processing if not already running
            if !isProcessing {
                Task {
                    await processQueue()
                }
            }
            
        } catch {
            print("Failed to add to queue: \(error)")
        }
    }
    
    // Process downloads in the queue
    private func processQueue() async {
        isProcessing = true
        
        // Continue while there are pending downloads
        while let nextDownload = downloads.first(where: { $0.state == .pending }) {
            currentDownload = nextDownload
            await downloadVideo(nextDownload)
        }
        
        currentDownload = nil
        isProcessing = false
    }
    
    // Download a single video
    private func downloadVideo(_ download: Download) async {
        // Update state
        download.state = .downloading(progress: 0.0)
        
        do {
            // Get cookies if needed
            var cookies: [HTTPCookie] = []
            if let domain = cookieManager.extractDomain(from: download.url) {
                cookies = try cookieManager.extractSafariCookies(for: domain)
            }
            
            // Create a progress handler
            let progressHandler: (DownloadProgress) -> Void = { progress in
                Task { @MainActor in
                    download.state = .downloading(progress: progress.percentage)
                }
            }
            
            // Perform the download
            if !cookies.isEmpty {
                try await ytdlpService.downloadVideoWithCookies(
                    url: download.url,
                    format: download.selectedFormat,
                    cookies: cookies,
                    to: download.outputPath,
                    progressHandler: progressHandler
                )
            } else {
                try await ytdlpService.downloadVideo(
                    url: download.url,
                    format: download.selectedFormat,
                    to: download.outputPath,
                    progressHandler: progressHandler
                )
            }
            
            // Success!
            download.state = .completed(fileURL: download.outputPath)
            
        } catch {
            download.state = .failed(error: error.localizedDescription)
        }
    }
    
    // Remove a download from the queue
    func removeDownload(_ download: Download) {
        download.cancel()
        downloads.removeAll { $0.id == download.id }
    }
    
    // Clear completed downloads
    func clearCompleted() {
        downloads.removeAll { download in
            if case .completed = download.state {
                return true
            }
            return false
        }
    }
    
    // Retry a failed download
    func retryDownload(_ download: Download) {
        download.state = .pending
        
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    // Cancel all active downloads
    func cancelAll() {
        for download in downloads {
            if download.state.isActive {
                download.cancel()
            }
        }
        isProcessing = false
        currentDownload = nil
    }
}
```

**Building the Queue UI:**

Now let's create a beautiful queue interface. Create `Views/QueueView.swift`:

```swift
import SwiftUI

struct QueueView: View {
    @ObservedObject var queueManager = QueueManager.shared
    @State private var urlToAdd = ""
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
            
            Divider()
            
            // Quick add bar
            QuickAddBar(urlToAdd: $urlToAdd)
            
            // Queue list
            if queueManager.downloads.isEmpty {
                EmptyQueueView()
            } else {
                QueueListView()
            }
            
            // Bottom toolbar
            BottomToolbar()
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

struct HeaderView: View {
    @ObservedObject var queueManager = QueueManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Download Queue")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if queueManager.isProcessing {
                    Text("Processing downloads...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(queueManager.downloads.count) items in queue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Queue controls
            HStack(spacing: 12) {
                if queueManager.isProcessing {
                    Button(action: { queueManager.cancelAll() }) {
                        Label("Stop All", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else if !queueManager.downloads.isEmpty {
                    Button(action: {
                        Task {
                            await queueManager.processQueue()
                        }
                    }) {
                        Label("Start Queue", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button(action: { queueManager.clearCompleted() }) {
                    Label("Clear Completed", systemImage: "trash")
                }
                .disabled(queueManager.downloads.allSatisfy { download in
                    if case .completed = download.state {
                        return false
                    }
                    return true
                })
            }
        }
        .padding()
    }
}

struct QuickAddBar: View {
    @Binding var urlToAdd: String
    @ObservedObject var queueManager = QueueManager.shared
    @State private var isAdding = false
    
    var body: some View {
        HStack(spacing: 12) {
            // URL input field
            TextField("Paste video URL here...", text: $urlToAdd)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    addURL()
                }
            
            // Add button
            Button(action: addURL) {
                if isAdding {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else {
                    Label("Add", systemImage: "plus")
                }
            }
            .disabled(urlToAdd.isEmpty || isAdding)
            
            // Paste button
            Button(action: pasteFromClipboard) {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func addURL() {
        guard !urlToAdd.isEmpty else { return }
        
        let url = urlToAdd
        urlToAdd = ""  // Clear the field immediately
        isAdding = true
        
        Task {
            await queueManager.addToQueue(url: url, useCookies: true)
            isAdding = false
        }
    }
    
    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            urlToAdd = string
        }
    }
}

struct EmptyQueueView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No downloads in queue")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Add URLs above to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QueueListView: View {
    @ObservedObject var queueManager = QueueManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(queueManager.downloads) { download in
                    DownloadRowView(download: download)
                        .transition(.asymmetric(
                            insertion: .slide.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding()
        }
        .animation(.spring(), value: queueManager.downloads.count)
    }
}

struct DownloadRowView: View {
    @ObservedObject var download: Download
    @ObservedObject var queueManager = QueueManager.shared
    @State private var isEditing = false
    @State private var editedFileName = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(download.state.statusColor)
                .frame(width: 8, height: 8)
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    // Editable filename
                    HStack {
                        TextField("Filename", text: $editedFileName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                download.customFileName = editedFileName
                                isEditing = false
                            }
                        
                        Text(".\(download.selectedFormat.ext)")
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Display filename
                    Text("\(download.customFileName).\(download.selectedFormat.ext)")
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            // Double-click to edit
                            editedFileName = download.customFileName
                            isEditing = true
                        }
                }
                
                // Status and progress
                HStack {
                    Text(download.state.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if case .downloading(let progress) = download.state {
                        // Progress bar
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Show in Finder button for completed downloads
                if case .completed(let fileURL) = download.state {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Show in Finder")
                }
                
                // Retry button for failed downloads
                if case .failed = download.state {
                    Button(action: {
                        queueManager.retryDownload(download)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Retry")
                }
                
                // Cancel/Remove button
                Button(action: {
                    queueManager.removeDownload(download)
                }) {
                    Image(systemName: download.state.isActive ? "stop.fill" : "xmark")
                        .foregroundColor(download.state.isActive ? .red : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help(download.state.isActive ? "Cancel" : "Remove")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct BottomToolbar: View {
    @ObservedObject var queueManager = QueueManager.shared
    
    // Calculate statistics
    var completedCount: Int {
        queueManager.downloads.filter { download in
            if case .completed = download.state { return true }
            return false
        }.count
    }
    
    var failedCount: Int {
        queueManager.downloads.filter { download in
            if case .failed = download.state { return true }
            return false
        }.count
    }
    
    var body: some View {
        HStack {
            // Statistics
            HStack(spacing: 16) {
                Label("\(completedCount) completed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                if failedCount > 0 {
                    Label("\(failedCount) failed", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
            
            Spacer()
            
            // Settings button
            Button(action: openSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func openSettings() {
        // We'll implement this in the afternoon
    }
}
```

### Afternoon: Cookie Perfection & Smart Features (3-4 hours)

Now let's perfect that cookie extraction system and add smart naming features that make yt-dlp-MAX invaluable.

**Enhanced Cookie Manager:**

Update your `CookieManager.swift` with multi-browser support:

```swift
import Foundation
import WebKit

class CookieManager {
    
    enum Browser: String, CaseIterable {
        case safari = "Safari"
        case chrome = "Chrome"
        case firefox = "Firefox"
        case brave = "Brave"
        case edge = "Edge"
        
        // Path to cookie database for each browser
        var cookiePath: String? {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            
            switch self {
            case .safari:
                // Safari uses a different system - we'll handle it specially
                return nil
                
            case .chrome:
                return "\(home)/Library/Application Support/Google/Chrome/Default/Cookies"
                
            case .brave:
                return "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies"
                
            case .edge:
                return "\(home)/Library/Application Support/Microsoft Edge/Default/Cookies"
                
            case .firefox:
                // Firefox uses a different format, more complex
                return "\(home)/Library/Application Support/Firefox/Profiles"
            }
        }
        
        var isInstalled: Bool {
            if self == .safari {
                return true  // Safari is always installed on macOS
            }
            
            guard let path = cookiePath else { return false }
            return FileManager.default.fileExists(atPath: path)
        }
    }
    
    // Get all installed browsers
    func getInstalledBrowsers() -> [Browser] {
        Browser.allCases.filter { $0.isInstalled }
    }
    
    // Extract cookies from any supported browser
    func extractCookies(from browser: Browser, for domain: String) async throws -> [HTTPCookie] {
        switch browser {
        case .safari:
            return try await extractSafariCookiesViaWebKit(for: domain)
            
        case .chrome, .brave, .edge:
            return try extractChromiumCookies(from: browser, for: domain)
            
        case .firefox:
            // Firefox is more complex, skip for now
            throw CookieError.browserNotSupported
        }
    }
    
    // Safari extraction using WebKit (shares cookies with Safari)
    @MainActor
    private func extractSafariCookiesViaWebKit(for domain: String) async throws -> [HTTPCookie] {
        // Create a hidden web view
        let webView = WKWebView()
        
        // Navigate to the domain to trigger cookie loading
        guard let url = URL(string: "https://\(domain)") else {
            throw CookieError.invalidDomain
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        // Wait a moment for cookies to load
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        
        // Get cookies from the web view
        let dataStore = webView.configuration.websiteDataStore
        let cookies = await dataStore.httpCookieStore.getAllCookies()
        
        // Filter for our domain
        return cookies.filter { cookie in
            cookie.domain.contains(domain) || domain.contains(cookie.domain)
        }
    }
    
    // Chromium-based browser extraction (Chrome, Brave, Edge)
    private func extractChromiumCookies(from browser: Browser, for domain: String) throws -> [HTTPCookie] {
        guard let cookiePath = browser.cookiePath else {
            throw CookieError.pathNotFound
        }
        
        // Chromium browsers use an encrypted SQLite database
        // For simplicity, we'll use a workaround approach here
        // In production, you'd need to handle the encryption properly
        
        // This is a simplified version - real implementation needs:
        // 1. Decrypt the cookies using Keychain data
        // 2. Parse the SQLite database
        // 3. Convert to HTTPCookie format
        
        print("Would extract cookies from: \(cookiePath)")
        
        // For now, return empty array
        // You can implement full Chromium cookie extraction later
        return []
    }
    
    // Smart domain extraction from various URL formats
    func extractDomain(from urlString: String) -> String? {
        // Handle various URL formats
        var cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add protocol if missing
        if !cleanURL.contains("://") {
            cleanURL = "https://\(cleanURL)"
        }
        
        guard let url = URL(string: cleanURL),
              let host = url.host else { return nil }
        
        // Extract main domain
        let components = host.components(separatedBy: ".")
        
        // Handle subdomains (www.youtube.com -> youtube.com)
        if components.count >= 2 {
            let mainComponents = components.suffix(2)
            return mainComponents.joined(separator: ".")
        }
        
        return host
    }
}

enum CookieError: LocalizedError {
    case browserNotSupported
    case pathNotFound
    case invalidDomain
    case extractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .browserNotSupported:
            return "This browser is not yet supported"
        case .pathNotFound:
            return "Could not find browser cookie storage"
        case .invalidDomain:
            return "Invalid domain name"
        case .extractionFailed(let reason):
            return "Cookie extraction failed: \(reason)"
        }
    }
}
```

**Smart File Naming System:**

Create `Views/FileNamingView.swift` for intelligent file naming:

```swift
import SwiftUI

struct FileNamingView: View {
    @ObservedObject var download: Download
    @State private var template = "{title}"
    @State private var preview = ""
    
    // Available template variables
    let templateVariables = [
        ("{title}", "Video title"),
        ("{channel}", "Channel/Uploader name"),
        ("{date}", "Upload date"),
        ("{id}", "Video ID"),
        ("{quality}", "Video quality"),
        ("{ext}", "File extension")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customize Filename")
                .font(.headline)
            
            // Template input
            HStack {
                TextField("Filename template", text: $template)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: template) { _ in
                        updatePreview()
                    }
                
                // Template help button
                Button(action: showTemplateHelp) {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Quick template buttons
            HStack(spacing: 8) {
                ForEach(templateVariables, id: \.0) { variable, description in
                    Button(variable.1) {
                        template += " \(variable.0)"
                        updatePreview()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(preview.isEmpty ? "filename.mp4" : "\(preview).\(download.selectedFormat.ext)")
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
            }
            
            // Apply button
            Button("Apply") {
                download.customFileName = parseTemplate(template)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            updatePreview()
        }
    }
    
    private func updatePreview() {
        preview = parseTemplate(template)
    }
    
    private func parseTemplate(_ template: String) -> String {
        var result = template
        
        // Replace template variables with actual values
        result = result.replacingOccurrences(of: "{title}", with: download.videoInfo.title)
        result = result.replacingOccurrences(of: "{channel}", with: download.videoInfo.uploader ?? "Unknown")
        result = result.replacingOccurrences(of: "{date}", with: formatDate(Date()))
        result = result.replacingOccurrences(of: "{id}", with: extractVideoId(from: download.url) ?? "")
        result = result.replacingOccurrences(of: "{quality}", with: download.selectedFormat.format_note ?? "")
        result = result.replacingOccurrences(of: "{ext}", with: download.selectedFormat.ext)
        
        // Clean up the filename
        return Download.sanitizeFileName(result)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func extractVideoId(from url: String) -> String? {
        // Extract YouTube video ID from URL
        if let urlComponents = URLComponents(string: url),
           let videoId = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        
        // Handle youtu.be format
        if url.contains("youtu.be/") {
            let components = url.components(separatedBy: "youtu.be/")
            if components.count > 1 {
                return components[1].components(separatedBy: "?")[0]
            }
        }
        
        return nil
    }
    
    private func showTemplateHelp() {
        // Show a popover with template documentation
    }
}
```

### Key Concepts You've Learned Today

Let me connect today's Swift patterns to concepts you already understand:

**The @MainActor Attribute**
This is Swift's way of saying "this code must run on the main thread." It's similar to using `DispatchQueue.main.async` in iOS development or `runOnUiThread` in Android. Any UI updates must happen on the main thread, and @MainActor ensures this automatically.

**ObservableObject and @Published**
These work together to create reactive objects. When you mark a class as ObservableObject and properties as @Published, SwiftUI automatically re-renders any views that depend on those properties. It's like MobX or Vue's reactivity system but built into the language.

**LazyVStack vs VStack**
LazyVStack only creates views as they become visible, like virtual scrolling in web frameworks. Use it for long lists to avoid creating hundreds of views at once. Regular VStack creates all its children immediately.

**Task and async/await**
Task creates a new asynchronous context, similar to spawning a promise in JavaScript. The key difference is that Swift's async/await is built on structured concurrency - tasks have clear ownership and cancellation is automatic when the parent scope ends.

### Testing Today's Code

Let's write tests for the queue system:

```swift
import XCTest
@testable import yt_dlp_MAX

class QueueManagerTests: XCTestCase {
    
    func testFileNameSanitization() {
        // Test that problematic characters are removed
        let badName = "Video: Test / With \\ Bad * Characters?"
        let sanitized = Download.sanitizeFileName(badName)
        
        XCTAssertFalse(sanitized.contains(":"))
        XCTAssertFalse(sanitized.contains("/"))
        XCTAssertFalse(sanitized.contains("?"))
        XCTAssertTrue(sanitized.contains("Video"))
        XCTAssertTrue(sanitized.contains("Test"))
    }
    
    func testQueueAddition() async {
        let manager = QueueManager.shared
        let initialCount = manager.downloads.count
        
        // Add a test URL
        await manager.addToQueue(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        
        // Verify it was added
        XCTAssertEqual(manager.downloads.count, initialCount + 1)
    }
    
    func testDownloadStateTransitions() {
        let videoInfo = VideoInfo(
            title: "Test Video",
            uploader: "Test Channel",
            duration: 100,
            webpage_url: "https://example.com",
            thumbnail: nil,
            formats: nil
        )
        
        let format = VideoFormat(
            format_id: "18",
            ext: "mp4",
            format_note: "360p",
            filesize: nil,
            vcodec: "h264",
            acodec: "aac"
        )
        
        let download = Download(
            url: "https://example.com",
            videoInfo: videoInfo,
            format: format,
            outputDirectory: URL(fileURLWithPath: "/tmp")
        )
        
        // Test initial state
        XCTAssertEqual(download.state, DownloadState.pending)
        
        // Test state changes
        download.state = .downloading(progress: 50.0)
        XCTAssertTrue(download.state.isActive)
        
        download.state = .completed(fileURL: URL(fileURLWithPath: "/tmp/test.mp4"))
        XCTAssertFalse(download.state.isActive)
    }
}
```

### Common Day 3 Challenges and Solutions

**"The queue UI doesn't update when downloads progress"**
Make sure your download state is marked with @Published and your views observe it with @ObservedObject or @StateObject. Also ensure progress updates happen on the main thread.

**"Cookie extraction isn't working"**
Safari is the easiest to start with because WebKit shares cookies. Chrome/Brave require more complex decryption that we simplified here. Start with Safari and add others later.

**"Files are being saved with weird names"**
The sanitization function removes problematic characters. Make sure you're calling it on all user-provided filenames. Also check that you're properly appending the file extension.

**"Multiple downloads aren't running simultaneously"**
The current implementation processes downloads sequentially. To run multiple downloads in parallel, you'd need to modify processQueue() to spawn multiple Tasks. Start with sequential for simplicity.

### End of Day 3 Checklist

By the end of Day 3, you should have:

- [ ] A working download queue that processes videos in order
- [ ] Ability to add multiple URLs quickly
- [ ] Custom file naming with templates
- [ ] Cookie extraction from at least Safari
- [ ] Visual feedback for download progress
- [ ] Ability to retry failed downloads
- [ ] Option to open completed downloads in Finder
- [ ] At least 3 passing tests

### Bonus Challenges If You Finish Early

1. **Parallel Downloads**: Modify processQueue() to handle multiple simultaneous downloads
2. **Playlist Support**: Detect playlist URLs and offer to add all videos
3. **Format Selection Per Download**: Let users choose different formats for each video
4. **Download Speed Display**: Parse and display download speed from yt-dlp output
5. **Time Remaining Estimate**: Calculate and display estimated completion time

### Connecting With Your Swift Mentor

Great questions to ask your mentor after Day 3:

1. "Should I use Combine for the progress updates instead of callbacks?"
2. "Is the singleton pattern for QueueManager appropriate here?"
3. "What's the best way to handle concurrent downloads safely?"
4. "Should I be using actors for thread safety instead of @MainActor?"

### Working with Claude Code Tomorrow

For Day 4, you'll want to focus on polish and preparing for real users. Start your Claude Code session with:

```
I'm on Day 4 of building yt-dlp-MAX. 
Days 1-3 completed: Basic UI, downloads work, queue system functional, cookies from Safari.

Today's goals:
1. Add preferences window
2. Improve error handling 
3. Add keyboard shortcuts
4. Create app icon
5. Test with real users

Current issues: [list any problems]

Please help me implement [specific feature] with explanations of any new Swift patterns.
```

### Reflecting on Your Progress

Take a moment to appreciate what you've accomplished. Three days ago, you had never written Swift code. Now you have a functional download manager with a queue system, custom naming, and cookie extraction. That's remarkable!

The queue system you built today is the heart of yt-dlp-MAX. Everything else is enhancement. You've solved the core problem: making yt-dlp accessible to users who don't want to use the command line.

Tomorrow (Day 4), we'll add the polish that distinguishes good apps from great ones. But even if you stopped here, you'd have something useful. That's the beauty of iterative development - every day, you ship something better than yesterday.

Ready for Day 4? Your app is really taking shape!
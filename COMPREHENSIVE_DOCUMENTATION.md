# Fetcha - Comprehensive Documentation

> **A modern, native macOS application for downloading videos with a clean and intuitive interface. Built with Swift and SwiftUI, Fetcha provides a powerful GUI for yt-dlp with browser cookie support and advanced features.**

## Table of Contents

1. [Introduction & Overview](#introduction--overview)
2. [Feature Set Documentation](#feature-set-documentation)
3. [Architecture & Code Organization](#architecture--code-organization)
4. [Key Components Deep Dive](#key-components-deep-dive)
5. [Implementation Patterns & Best Practices](#implementation-patterns--best-practices)
6. [User Interface & User Experience](#user-interface--user-experience)
7. [System Integration](#system-integration)
8. [Development Status & Roadmap](#development-status--roadmap)
9. [Testing & Quality Assurance](#testing--quality-assurance)
10. [Developer Reference](#developer-reference)

---

## Introduction & Overview

### What is Fetcha?

Fetcha (originally yt-dlp-MAX) is a sophisticated macOS application that provides a beautiful, native interface for downloading videos from the internet. Unlike command-line tools or web-based solutions, Fetcha brings the power of yt-dlp to macOS users through a carefully crafted SwiftUI interface that follows native design patterns and user expectations.

### Key Distinguishing Features

**Native Performance**: Built entirely in Swift and SwiftUI, Fetcha delivers native macOS performance without the overhead of cross-platform frameworks. The app follows Apple's Human Interface Guidelines and integrates seamlessly with the macOS ecosystem.

**Intelligent Download Management**: Fetcha automatically detects optimal video formats, handles audio/video merging, and provides real-time progress tracking with detailed statistics including download speed, ETA, and file size estimates.

**Browser Cookie Integration**: One of Fetcha's standout features is its ability to extract cookies from major browsers (Safari, Chrome, Brave, Firefox, Edge) to download private, age-restricted, or subscription-only content that would otherwise be inaccessible.

**Advanced Queue System**: The application features a sophisticated download queue with support for concurrent downloads, drag-and-drop reordering, priority management, and automatic retry mechanisms.

### Target Audience

- **Content Creators**: Who need to download reference materials, backup their own content, or work with media offline
- **Researchers and Educators**: Who require reliable access to video content for academic or educational purposes  
- **Media Professionals**: Who work with video content and need high-quality downloads with specific format requirements
- **Power Users**: Who want more control and visibility than web-based downloaders provide
- **macOS Users**: Who prefer native applications that integrate well with their operating system

### Use Cases

- Downloading educational content for offline viewing
- Archiving important videos for long-term preservation
- Creating local libraries of reference materials
- Backing up user-generated content
- Research and analysis of video content
- Converting videos between formats for specific needs

---

## Feature Set Documentation

### Core Download Functionality

**yt-dlp Integration**: Fetcha leverages the powerful yt-dlp library, providing access to hundreds of supported websites including YouTube, Vimeo, Twitter/X, and many others. The integration is seamless, with automatic binary discovery and version management.

```swift
// Example of yt-dlp service initialization
private func findYTDLP() -> String? {
    let possiblePaths = [
        "/opt/homebrew/bin/yt-dlp",     // Apple Silicon Homebrew
        "/usr/local/bin/yt-dlp",        // Intel Homebrew
        "/usr/bin/yt-dlp",              // System install
        // Bundled version support for distribution
        Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "bin")
    ]
    // Systematic path checking with fallback to 'which' command
}
```

**Metadata Extraction**: Before downloading, Fetcha fetches comprehensive video metadata including title, description, thumbnail, duration, uploader information, and available formats. This information is parsed from JSON output and presented in a user-friendly interface.

### Smart Format Selection

**Automatic Quality Detection**: The app analyzes available formats and automatically selects the best quality option based on user preferences. The selection logic considers video resolution, audio quality, codec compatibility, and file size.

```swift
// Format selection logic
var bestFormat: VideoFormat? {
    guard let formats = formats else { return nil }
    
    // Prefer formats with both video and audio
    let combinedFormats = formats.filter { format in
        format.vcodec != nil && format.vcodec != "none" &&
        format.acodec != nil && format.acodec != "none"
    }
    
    // Sort by quality and return the best
    return combinedFormats.max { first, second in
        (first.height ?? 0) < (second.height ?? 0)
    }
}
```

**Manual Format Selection**: Power users can manually select specific formats, including video-only or audio-only downloads. The interface displays technical details like codecs, bitrates, and file sizes to aid in decision-making.

**Audio/Video Merging**: When necessary, Fetcha automatically merges separate video and audio streams using ffmpeg, ensuring optimal quality while maintaining format compatibility.

### Browser Cookie Support

**Multi-Browser Support**: Fetcha supports cookie extraction from all major browsers on macOS:
- Safari (using native cookie store access)
- Chrome (reading encrypted cookie database)
- Brave (Chrome-compatible implementation)
- Firefox (SQLite database parsing)
- Microsoft Edge (Chrome-compatible)

**Secure Cookie Handling**: Cookie extraction is performed securely with proper permission handling. The app requires browsers to be closed during extraction to ensure data integrity.

**Private Content Access**: With proper authentication cookies, Fetcha can download:
- Age-restricted content
- Private videos (with proper permissions)
- Subscription-only content
- Region-locked material

### Advanced Queue Management

**Concurrent Downloads**: The queue system supports multiple simultaneous downloads (configurable from 1-10) with intelligent resource management to prevent system overload.

**Priority System**: Users can reorder downloads by dragging items in the queue or using priority controls. The queue processes items based on their position and status.

**Automatic Retry**: Failed downloads are automatically retried with exponential backoff. Users can configure the number of retry attempts and conditions.

**Queue Persistence**: The download queue persists across app restarts, maintaining state and progress information.

### Real-Time Progress Tracking

**Detailed Progress Information**: For each download, Fetcha displays:
- Download percentage with animated progress bars
- Current download speed (MB/s, KB/s)
- Estimated time remaining (ETA)
- File size (actual and estimated)
- Current status (downloading, merging, completed, failed)

**Visual Feedback**: Progress is displayed through multiple visual elements:
- Individual progress bars for each queue item
- Overall queue progress indicator
- Status icons and color coding
- Real-time speed and ETA updates

### Playlist Handling

**Playlist Detection**: Fetcha automatically detects when a URL points to a playlist and provides options for handling:
- Download all videos in the playlist
- Download a specific range of videos
- Download only the first video
- Show confirmation dialog with playlist details

**Playlist Management**: For playlist downloads, the app provides:
- Preview of all videos in the playlist
- Selective download options
- Duplicate detection and skipping
- Reverse order downloading
- Playlist limit enforcement

### Customization and Preferences

**Download Locations**: Users can configure separate download locations for:
- Standard video files
- Audio-only downloads
- Video-only downloads (no audio)
- Merged audio/video files

**File Naming**: Advanced file naming templates support:
- Video title, uploader, upload date
- Playlist information and indexing
- Custom format strings
- Special character handling and sanitization

**Quality Preferences**: Global quality settings include:
- Default video quality (4K, 1080p, 720p, etc.)
- Audio format preferences (MP3, M4A, FLAC, etc.)
- Codec preferences and compatibility options

---

## Architecture & Code Organization

### MVVM Pattern Implementation

Fetcha follows the Model-View-ViewModel (MVVM) architectural pattern, providing clear separation of concerns and maintainable code structure.

**Models** (`/Models/`):
- `VideoInfo.swift`: Core data structure for video metadata
- `VideoFormat.swift`: Represents downloadable formats with quality information
- `DownloadTask.swift`: Individual download task representation
- `AppPreferences.swift`: Application settings and configuration

**Views** (`/Views/`):
- SwiftUI components for user interface elements
- Reactive UI updates through Combine publishers
- Modular, reusable interface components

**Services** (`/Services/`):
- Business logic separated from UI concerns
- API interfaces for external integrations
- State management and data persistence

### Service Layer Architecture

The application uses a clean service layer architecture that separates concerns and provides extensibility:

```swift
// Service protocol pattern for consistency
protocol ServiceProtocol {
    var identifier: String { get }
    func initialize() async throws
    func shutdown() async
    var isHealthy: Bool { get }
}
```

**YTDLPService**: Core integration with the yt-dlp binary
- Binary discovery and version management
- Process execution and output parsing
- Error handling and recovery
- Cookie integration and security

**DownloadQueue**: Queue management and coordination
- Concurrent download scheduling
- Progress tracking and state management
- File system integration
- History and logging

**ProcessManager**: System process lifecycle management
- Safe process spawning and cleanup
- Resource monitoring and limits
- Graceful shutdown handling
- Memory and CPU usage optimization

### Event-Driven Design Patterns

Fetcha implements event-driven architecture to support future extensibility and automation:

```swift
enum AppEvent {
    case downloadQueued(id: UUID, url: String)
    case downloadStarted(id: UUID)
    case downloadProgress(id: UUID, progress: Double)
    case downloadCompleted(id: UUID, file: URL)
    case downloadFailed(id: UUID, error: Error)
}

class EventBus {
    static let shared = EventBus()
    private let subject = PassthroughSubject<AppEvent, Never>()
    
    func emit(_ event: AppEvent) {
        subject.send(event)
        // Future: webhook notifications, API events
    }
}
```

### Data Flow Architecture

The application follows unidirectional data flow principles:

1. **User Actions**: Triggered in Views
2. **Business Logic**: Processed in Services
3. **State Updates**: Published through ObservableObjects
4. **UI Updates**: Automatically triggered by SwiftUI

This pattern ensures predictable state management and easier debugging.

---

## Key Components Deep Dive

### YTDLPService: Core Download Engine

The `YTDLPService` class serves as the primary interface between Fetcha and the yt-dlp binary, handling all aspects of video downloading and metadata extraction.

**Binary Management**:
```swift
private func findYTDLP() -> String? {
    // Priority search order:
    // 1. Bundled application resources
    // 2. Homebrew installations (Apple Silicon and Intel)
    // 3. System-wide installations
    // 4. User-specific installations
    // 5. PATH-based discovery using 'which'
}
```

**Process Execution**: The service manages yt-dlp processes with sophisticated error handling, timeout management, and output parsing. Each download runs in its own process with dedicated pipes for standard output and error streams.

**Cookie Integration**: Seamless browser cookie extraction for accessing private content:
```swift
switch preferences.cookieSource {
case "safari":
    arguments.append(contentsOf: ["--cookies-from-browser", "safari"])
case "firefox":
    // Domain filtering to prevent HTTP 413 errors
    arguments.append(contentsOf: ["--cookies-from-browser", "firefox:*.youtube.com,*.googlevideo.com"])
}
```

**Progress Parsing**: Real-time parsing of yt-dlp output to extract download progress, speed, and ETA information using regular expressions and pattern matching.

### DownloadQueue: Queue Management System

The `DownloadQueue` class orchestrates the entire download process, managing concurrent operations while providing a clean interface for user interaction.

**Concurrent Download Management**:
```swift
func processQueue() {
    Task {
        while activeDownloads.count < maxConcurrentDownloads {
            guard let nextItem = items.first(where: { $0.status == .waiting }) else {
                break
            }
            
            Task {
                await startDownload(nextItem)
            }
            
            // Prevent race conditions
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
```

**State Management**: The queue maintains comprehensive state for each download including progress, status, error messages, and metadata. State updates are published to the UI through Combine publishers.

**Persistence**: Queue state persists across application restarts, maintaining download history and allowing users to resume interrupted sessions.

### ProcessManager: System Process Lifecycle

The `ProcessManager` provides centralized management of all system processes spawned by the application, ensuring clean resource usage and preventing runaway processes.

**Process Registration**:
```swift
@MainActor
class ProcessManager: ObservableObject {
    private var activeProcesses: Set<Process> = []
    
    func register(_ process: Process) async {
        activeProcesses.insert(process)
    }
    
    func terminate(_ process: Process, timeout: TimeInterval = 5.0) {
        // Graceful termination with fallback to force kill
    }
}
```

**Cleanup Guarantees**: The process manager ensures all spawned processes are properly terminated when the application exits, preventing zombie processes and resource leaks.

**Timeout Handling**: Automatic timeout handling prevents hung processes from consuming system resources indefinitely.

### AppPreferences: Configuration Management

The `AppPreferences` class provides centralized configuration management using SwiftUI's `@AppStorage` property wrapper for automatic persistence.

**Preference Categories**:
- Download behavior and quality settings
- File naming and organization options
- Browser cookie source configuration
- Queue management parameters
- UI customization options

**Reactive Updates**: Preference changes automatically propagate throughout the application using Combine publishers, ensuring immediate UI updates and behavior changes.

### ContentView: Main UI Orchestration

The main `ContentView` serves as the primary interface coordinator, managing the three-panel layout and user interactions.

**Panel Management**:
- History panel (left): Download history and file browser
- Main panel (center): URL input and download queue
- Details panel (right): Video information and format selection

**Dynamic Layout**: Panels can be shown/hidden with smooth animations, and the main panel adjusts its minimum width based on visible panels.

**Clipboard Monitoring**: Automatic detection of URLs in the clipboard with configurable auto-queueing behavior.

---

## Implementation Patterns & Best Practices

### Async/Await Concurrency

Fetcha extensively uses Swift's modern async/await concurrency model for all I/O operations:

```swift
func fetchMetadata(for urlString: String) async throws -> VideoInfo {
    let process = Process()
    // Configure process...
    
    try await process.runWithTimeout(timeout: 30.0)
    
    // Parse JSON response
    let videoInfo = try JSONDecoder().decode(VideoInfo.self, from: data)
    return videoInfo
}
```

**Benefits**:
- Eliminates callback hell and simplifies error handling
- Provides natural cancellation support
- Integrates seamlessly with SwiftUI's reactive updates
- Enables structured concurrency patterns

### Combine Framework Integration

The application uses Combine for reactive programming and state management:

```swift
// Reactive UI updates
@StateObject private var downloadQueue = DownloadQueue()

// Automatic preference synchronization
preferences.objectWillChange
    .sink { [weak self] _ in
        self?.updateConfiguration()
    }
    .store(in: &cancellables)
```

### ObservableObject Pattern

State management follows the ObservableObject pattern for automatic UI updates:

```swift
class QueueItem: Identifiable, ObservableObject {
    @Published var status: DownloadStatus = .waiting
    @Published var progress: Double = 0
    @Published var speed: String = ""
    @Published var eta: String = ""
}
```

### Error Handling and Recovery

Comprehensive error handling with user-friendly messaging:

```swift
enum YTDLPError: LocalizedError {
    case ytdlpNotFound
    case invalidJSON(String)
    case processFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .ytdlpNotFound:
            return "yt-dlp is not installed. Please install it using: brew install yt-dlp"
        case .invalidJSON(let details):
            return "Failed to parse video information: \(details)"
        case .processFailed(let details):
            return "yt-dlp process failed: \(details)"
        }
    }
}
```

### Security and Sandboxing

The application implements proper security measures:
- App sandboxing with necessary entitlements
- Secure cookie extraction with proper permission handling
- Input validation for URLs and file paths
- Process isolation and resource limits

---

## User Interface & User Experience

### Three-Panel Layout Design

Fetcha's interface is built around a flexible three-panel layout that adapts to user needs and window sizes:

**History Panel (Left)**:
- Recent download history with search capabilities
- File system browser for downloaded content
- Quick access to previously downloaded videos
- Thumbnail previews and metadata display

**Main Panel (Center)**:
- URL input field with paste button
- Download queue with drag-and-drop reordering
- Real-time progress indicators
- Status messages and error notifications

**Details Panel (Right)**:
- Video metadata display (title, description, duration)
- Thumbnail preview
- Format selection interface
- Download statistics and information

### Dynamic Panel Management

The interface adapts intelligently to screen size and user preferences:

```swift
// Automatic panel width adjustment
private func autoAdjustPanelWidth() {
    guard let window = NSApplication.shared.windows.first else { return }
    let windowWidth = window.frame.width
    
    if windowWidth < 800 {
        // Close secondary panels on small screens
        if showHistoryPanel && showDetailsPanel {
            showDetailsPanel = false
        }
        historyPanelWidth = 250  // Minimum width
    } else if windowWidth < 1200 {
        historyPanelWidth = min(300, windowWidth * 0.25)
    } else {
        historyPanelWidth = min(400, windowWidth * 0.3)
    }
}
```

### Progress Visualization

Multiple layers of progress feedback keep users informed:

**Individual Item Progress**:
- Animated progress bars with smooth transitions
- Color-coded status indicators
- Real-time speed and ETA display
- Status text with detailed information

**Overall Queue Progress**:
- Combined progress bar showing total completion
- Active download count indicator
- Shimmer effects for visual feedback during downloads

### Keyboard Navigation

The interface supports comprehensive keyboard navigation:
- Tab navigation through all controls
- Arrow keys for queue item selection
- Space bar for play/pause actions
- Command key combinations for common actions

### Accessibility Features

Fetcha includes accessibility features for users with disabilities:
- VoiceOver support with descriptive labels
- High contrast mode compatibility
- Keyboard-only navigation support
- Screen reader friendly status updates

---

## System Integration

### yt-dlp and ffmpeg Integration

Fetcha integrates deeply with the yt-dlp ecosystem while maintaining user-friendly abstractions:

**Binary Discovery**: Systematic search for installed binaries with multiple fallback strategies:
```swift
let possiblePaths = [
    "/opt/homebrew/bin/yt-dlp",     // Apple Silicon Homebrew
    "/usr/local/bin/yt-dlp",        // Intel Homebrew
    "/usr/bin/yt-dlp",              // System install
    Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "bin")
]
```

**Process Management**: Safe process execution with timeout handling and resource cleanup:
- Dedicated process threads to prevent UI blocking
- Automatic cleanup on application exit
- Resource monitoring and limits
- Graceful error handling and recovery

**Output Parsing**: Real-time parsing of yt-dlp output streams for progress tracking and error detection.

### Browser Cookie Extraction

Sophisticated cookie extraction system supporting all major browsers:

**Safari Integration**: Native cookie store access using macOS APIs
**Chrome/Brave/Edge**: Encrypted database reading with proper decryption
**Firefox**: SQLite database parsing with domain filtering
**Security**: Proper permission handling and temporary file management

### File System Operations

Comprehensive file system integration:

**Download Location Management**:
- Separate folders for different content types
- Automatic directory creation
- Path validation and sanitization
- Disk space monitoring

**File Organization**:
- Template-based naming systems
- Duplicate detection and handling
- Metadata preservation
- Thumbnail caching

### macOS-Specific Features

Native macOS integration includes:

**Finder Integration**:
- Quick Look support for downloaded files
- Spotlight metadata indexing
- Tags and extended attributes
- Custom file icons

**System Services**:
- Share extension support
- Drag-and-drop from other applications
- URL scheme handling
- Notification center integration

**Security Model**:
- App sandboxing compliance
- Hardened runtime support
- Code signing and notarization
- Privacy-preserving cookie access

---

## Development Status & Roadmap

### Current Implementation (Phase 4-5)

Fetcha is currently in active development with the following implemented features:

**Core Functionality** (Complete):
- yt-dlp integration and process management
- Video metadata extraction and parsing
- Download queue with concurrent processing
- Browser cookie extraction
- Real-time progress tracking
- Format selection and quality management

**User Interface** (Complete):
- Three-panel SwiftUI layout
- Drag-and-drop queue management
- Preferences interface
- Debug console and logging
- Responsive design and animations

**Advanced Features** (In Progress):
- Playlist handling and batch downloads
- Advanced file naming templates
- Performance optimization
- Error recovery and retry logic

### Future Evolution Plans

The application is architected with future expansion in mind, following a clear roadmap:

**Stage A - API Server Integration**:
- RESTful API server for automation
- Webhook support for external integrations
- Remote queue management
- Multi-device synchronization

**Stage B - Cloud Storage Integration**:
- Direct upload to cloud providers (Dropbox, Google Drive, S3)
- Streaming download and upload
- Distributed storage management
- Bandwidth optimization

**Stage C - AI and Semantic Search**:
- Content categorization using machine learning
- Intelligent tagging and metadata enrichment
- Semantic search across downloaded content
- Duplicate detection using content analysis

**Stage D - Media Server Evolution**:
- Direct streaming to devices
- Transcoding and format optimization
- Jellyfin/Plex integration
- Home theater system support

### Architecture Principles for Extensibility

The codebase follows specific principles to enable future evolution:

**Separation of Concerns**:
```swift
// Services are isolated and protocol-based
protocol DownloadServiceProtocol {
    func download(url: String) async throws -> URL
}

class YTDLPDownloadService: DownloadServiceProtocol {
    // Current implementation
}

class CloudDownloadService: DownloadServiceProtocol {
    // Future cloud-based implementation
}
```

**Event-Driven Architecture**:
- All state changes emit events for external consumption
- Webhook-ready event system
- Plugin architecture foundations

**Storage Abstraction**:
- Pluggable storage backends
- Local, network, and cloud storage support
- Consistent API across storage types

### Development Roadmap

**Phase 5 - Pro Features** (Current):
- Advanced playlist management
- Custom post-processing scripts
- Metadata editing capabilities
- Performance optimization

**Phase 6 - API Foundation**:
- HTTP API server implementation
- Authentication and authorization
- Rate limiting and resource management
- Documentation and SDK development

**Phase 7 - Cloud Integration**:
- Storage provider plugins
- Streaming capabilities
- Distributed architecture
- Multi-tenant support

---

## Testing & Quality Assurance

### Test Coverage Areas

Fetcha includes comprehensive testing across multiple domains:

**URL Validation Tests** (`URLValidationTests.swift`):
```swift
func testYouTubeURLValidation() {
    let validURLs = [
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtu.be/dQw4w9WgXcQ",
        "https://m.youtube.com/watch?v=dQw4w9WgXcQ"
    ]
    
    for url in validURLs {
        XCTAssertTrue(isValidURL(url), "Should validate YouTube URL: \(url)")
    }
}
```

**Cookie Extraction Tests** (`CookieExtractionTests.swift`):
- Browser-specific cookie extraction validation
- Security and permission handling
- Error recovery and fallback mechanisms

**Playlist Detection Tests** (`PlaylistDetectionTests.swift`):
- Playlist URL recognition
- Video count extraction
- Metadata parsing accuracy

### Performance Testing

**Download Performance Tests** (`PerformanceTests.swift`):
- Concurrent download efficiency
- Memory usage monitoring
- CPU utilization optimization
- Network bandwidth management

**Queue Management Tests** (`QueueManagementTests.swift`):
- Large queue handling (1000+ items)
- Priority queue performance
- State persistence and recovery

### Error Handling Verification

**Process Management Tests**:
- Timeout handling validation
- Resource cleanup verification
- Error recovery testing
- Memory leak detection

**Network Error Tests**:
- Connectivity failure handling
- Retry mechanism validation
- Graceful degradation testing

### Quality Control Processes

**Automated Testing Pipeline**:
- Unit tests for all core functionality
- Integration tests for system components
- UI tests for user interaction flows
- Performance benchmarks and regression testing

**Code Quality Metrics**:
- Swift linting and style enforcement
- Code coverage reporting
- Static analysis for potential issues
- Memory and performance profiling

---

## Developer Reference

### Key Design Patterns

**Service Layer Pattern**:
```swift
protocol ServiceProtocol {
    var identifier: String { get }
    func initialize() async throws
    func shutdown() async
    var isHealthy: Bool { get }
}

class YTDLPService: ServiceProtocol {
    let identifier = "com.fetcha.ytdlp"
    
    func initialize() async throws {
        guard findYTDLP() != nil else {
            throw YTDLPError.ytdlpNotFound
        }
    }
    
    var isHealthy: Bool {
        return cachedYTDLPPath != nil
    }
}
```

**Repository Pattern for Data Access**:
```swift
protocol DownloadHistoryProtocol {
    func addToHistory(_ item: DownloadHistoryItem) async
    func getHistory(limit: Int) async -> [DownloadHistoryItem]
    func clearHistory() async
}

class DownloadHistory: DownloadHistoryProtocol {
    // Implementation with Core Data or other persistence
}
```

### Extension Points for Customization

**Plugin Architecture Foundation**:
```swift
protocol DownloadPlugin {
    func willStartDownload(task: DownloadTask) async throws
    func didCompleteDownload(task: DownloadTask, file: URL) async
    func shouldRetry(task: DownloadTask, error: Error) -> Bool
}

class PluginManager {
    private var plugins: [DownloadPlugin] = []
    
    func register(_ plugin: DownloadPlugin) {
        plugins.append(plugin)
    }
    
    func notifyWillStart(_ task: DownloadTask) async {
        for plugin in plugins {
            try? await plugin.willStartDownload(task: task)
        }
    }
}
```

### Build and Deployment

**Development Build**:
```bash
# Open project in Xcode
open yt-dlp-MAX.xcodeproj

# Command-line build
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX build
```

**Release Build**:
```bash
# Release configuration
xcodebuild -project yt-dlp-MAX.xcodeproj \
           -scheme yt-dlp-MAX \
           -configuration Release \
           -archivePath ./build/Fetcha.xcarchive \
           archive

# Package for distribution
./package_for_distribution.sh
```

**Testing Commands**:
```bash
# Run all tests
xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX

# Run specific test suite
xcodebuild test -project yt-dlp-MAX.xcodeproj \
                -scheme yt-dlp-MAX \
                -only-testing:yt_dlp_MAXTests/URLValidationTests
```

### Debugging Techniques

**Debug Console Integration**:
The application includes a built-in debug console accessible through the UI, providing real-time logging and diagnostics.

**Process Monitoring**:
```swift
// Monitor active processes
ProcessManager.shared.activeCount  // Number of active downloads

// Debug process execution
DebugLogger.shared.log("Process started", level: .info, details: fullCommand)
```

**State Inspection**:
```swift
// Queue state debugging
print("Queue items: \(downloadQueue.items.count)")
print("Active downloads: \(downloadQueue.activeDownloads.count)")

// Preference debugging
print("Current preferences: \(AppPreferences.shared)")
```

### Common Customization Examples

**Adding New Video Services**:
```swift
extension YTDLPService {
    func supportedSites() async throws -> [String] {
        // Query yt-dlp for supported extractors
        let output = try await runYTDLPCommand(["--list-extractors"])
        return parseExtractorList(output)
    }
}
```

**Custom File Naming**:
```swift
// Extend naming template support
extension AppPreferences {
    var customNamingTemplate: String {
        return namingTemplate
            .replacingOccurrences(of: "%(custom_field)s", with: customValue)
    }
}
```

**Event System Integration**:
```swift
// Subscribe to application events
EventBus.shared.publisher
    .filter { event in
        if case .downloadCompleted = event { return true }
        return false
    }
    .sink { event in
        // Custom handling for completed downloads
        handleDownloadCompletion(event)
    }
    .store(in: &cancellables)
```

---

## Conclusion

Fetcha represents a sophisticated approach to video downloading on macOS, combining native performance with powerful functionality. The application's architecture is designed for both current usability and future extensibility, following modern Swift development patterns and macOS design principles.

The codebase demonstrates excellent separation of concerns, comprehensive error handling, and thoughtful user experience design. With its foundation of protocols, event-driven architecture, and modular services, Fetcha is well-positioned for the ambitious evolution outlined in its roadmap.

Whether used as a simple video downloader or as a foundation for more complex media management workflows, Fetcha provides a robust, maintainable platform that showcases the power of native macOS development with Swift and SwiftUI.

---

*This documentation reflects the current state of the Fetcha codebase as of 2025. For the most up-to-date information, please refer to the source code and accompanying documentation files.*
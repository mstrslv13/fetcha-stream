# Fetcha (yt-dlp-MAX) - Comprehensive Documentation

## What is Fetcha?

**Fetcha** (formerly yt-dlp-MAX) is a native macOS application that provides a beautiful, intuitive graphical interface for downloading web media content. Built with Swift and SwiftUI, it leverages the power of yt-dlp while presenting a user experience that follows Apple's design principles and the "VLC model" - simple for beginners, powerful when needed.

### Core Purpose
Fetcha transforms the complex command-line functionality of yt-dlp into an accessible, native Mac experience. Whether you're saving tutorials for offline viewing, archiving content, or building a media library, Fetcha makes the process effortless without requiring any command-line knowledge.

### Key Differentiators
- **100% Native macOS**: Built specifically for Mac with SwiftUI, not a cross-platform port
- **Zero Configuration**: Works immediately after installation with smart defaults
- **Browser Integration**: Automatically extracts cookies from Safari, Chrome, Firefox, Brave, and Edge
- **Intelligent Queue Management**: Concurrent downloads with smart prioritization
- **Privacy-First**: All processing happens locally, no data collection or cloud services

## Current Feature Set

### Core Download Functionality

#### Smart URL Detection
- **Automatic Clipboard Monitoring**: Continuously monitors clipboard for valid URLs
- **Instant Recognition**: Supports 1000+ websites through yt-dlp
- **Auto-Queue Mode**: Option to automatically add copied URLs to download queue
- **Validation**: Real-time URL validation with pattern matching for major platforms

#### Format Selection
- **Automatic Best Quality**: Intelligently selects optimal format balancing quality and compatibility
- **Manual Selection**: Choose specific formats, codecs, and resolutions
- **Format Grouping**: Formats organized by quality (4K, 1080p, 720p, etc.)
- **Smart Merging**: Automatically combines separate video/audio streams when needed

#### Download Queue System
- **Concurrent Downloads**: Configurable parallel downloads (1-10 simultaneous)
- **Drag-and-Drop Reordering**: Visual queue management with drag handles
- **Priority System**: Waiting, downloading, paused, completed, and failed states
- **Batch Operations**: Pause all, resume all, clear completed
- **Progress Tracking**: Real-time speed, progress percentage, and ETA

### Advanced Features

#### Browser Cookie Support
- **Automatic Extraction**: Reads cookies from installed browsers without manual export
- **Multi-Browser Support**: Safari, Chrome, Firefox, Brave, Edge, Opera, Vivaldi
- **Private Content Access**: Download age-restricted or member-only content
- **Secure Handling**: Cookies read on-demand, never stored by the app

#### Playlist Handling
- **Smart Detection**: Automatically identifies playlists vs single videos
- **Flexible Options**: Download all, single video, or custom range
- **Reverse Order**: Option to download playlists in reverse chronological order
- **Duplicate Prevention**: Skip already downloaded videos
- **Batch Metadata**: Fetches metadata for all playlist items

#### File Management
- **Custom Naming Templates**: Use yt-dlp variables for organized downloads
- **Separate Locations**: Different folders for video, audio, and merged files
- **Subfolder Creation**: Automatic organization by channel, date, or format
- **Filename Sanitization**: Remove special characters, limit length
- **Post-Processing**: Embed thumbnails, subtitles, metadata

### User Interface Features

#### Three-Panel Layout
1. **History Panel** (Left)
   - Download history with search
   - Quick re-download functionality
   - File location shortcuts
   - Resizable with smooth animations

2. **Main Queue** (Center)
   - URL input with paste button
   - Active queue display
   - Overall progress bar
   - Status messages

3. **Details Panel** (Right)
   - Video thumbnail preview
   - Metadata display
   - Format selection
   - Download options

#### Visual Feedback
- **Animated Progress Bars**: Smooth animations with shimmer effects
- **Status Icons**: Clear visual indicators for each download state
- **Color Coding**: Green for success, yellow for active, red for errors
- **Real-time Updates**: Live speed, progress, and time remaining

## Architecture & Code Organization

### Design Pattern: MVVM with Services

The application follows a modified MVVM (Model-View-ViewModel) pattern with a service layer for business logic separation:

```
yt-dlp-MAX/
├── Models/                 # Data structures
│   ├── VideoInfo.swift     # Video metadata models
│   ├── DownloadTask.swift  # Download task state
│   └── AppPreferences.swift # User preferences
├── Services/              # Business logic layer
│   ├── YTDLPService.swift # yt-dlp integration
│   ├── DownloadQueue.swift # Queue management
│   ├── ProcessManager.swift # Process lifecycle
│   ├── DownloadHistory.swift # History tracking
│   └── PersistentDebugLogger.swift # Logging
├── Views/                 # SwiftUI components
│   ├── ContentView.swift  # Main window
│   ├── EnhancedQueueView.swift # Queue display
│   ├── PreferencesView.swift # Settings window
│   └── [Multiple view components]
└── yt_dlp_MAXApp.swift   # Application entry point
```

### Key Architectural Decisions

#### 1. Service-Oriented Architecture
- Services are singleton instances managing specific domains
- Clear separation between UI state and business logic
- Services communicate through Combine publishers

#### 2. Process Management Strategy
- Centralized ProcessManager prevents zombie processes
- Automatic cleanup on app termination
- Graceful shutdown with timeout fallbacks

#### 3. Reactive UI Updates
- @Published properties for real-time updates
- ObservableObject pattern for shared state
- Combine framework for event propagation

## Key Components Deep Dive

### YTDLPService
**Location**: `yt-dlp-MAX/Services/YTDLPService.swift`

The core service handling all yt-dlp interactions:

#### Responsibilities
- Binary discovery (bundled or system-installed)
- Metadata fetching with JSON parsing
- Download execution with progress parsing
- Cookie extraction and browser integration
- Format selection and quality optimization

#### Key Methods
- `findYTDLP()`: Searches multiple paths for yt-dlp binary
- `fetchMetadata()`: Retrieves video information
- `downloadVideo()`: Executes download with progress tracking
- `extractCookies()`: Handles browser cookie extraction
- `checkForPlaylist()`: Detects playlist URLs

#### Implementation Highlights
```swift
// Smart binary discovery with fallback chain
1. Check bundled Resources/bin directory
2. Search Homebrew paths (Intel and Apple Silicon)
3. Check system paths
4. Fall back to 'which' command
```

### DownloadQueue
**Location**: `yt-dlp-MAX/Services/DownloadQueue.swift`

Manages the download queue with concurrent execution:

#### Features
- Configurable concurrent download limits (1-10)
- Priority-based queue processing
- Automatic retry on failure
- Smart format selection per preferences
- Location management based on file type

#### Queue States
- **Waiting**: Queued for download
- **Downloading**: Actively downloading
- **Paused**: User-paused
- **Completed**: Successfully downloaded
- **Failed**: Error occurred

### ProcessManager
**Location**: `yt-dlp-MAX/Services/ProcessManager.swift`

Singleton managing all spawned processes:

#### Safety Features
- Process registration and tracking
- Graceful termination with timeout
- Force kill fallback (SIGKILL)
- Automatic cleanup on app quit
- Prevents process orphaning

### AppPreferences
**Location**: `yt-dlp-MAX/Models/AppPreferences.swift`

Centralized preferences using @AppStorage:

#### Key Settings
- Download paths (video, audio, merged)
- Quality preferences (best, 4K, 1080p, etc.)
- Browser cookie source selection
- Playlist handling (ask, all, single)
- File naming templates
- Concurrent download limits
- Auto-queue behavior

## Implementation Patterns

### Async/Await for Concurrency
```swift
Task {
    do {
        let metadata = try await ytdlpService.fetchMetadata(for: url)
        await MainActor.run {
            self.videoInfo = metadata
        }
    } catch {
        // Error handling
    }
}
```

### Combine for Reactive Updates
```swift
@Published var items: [QueueItem] = []

preferences.objectWillChange
    .sink { _ in
        // React to preference changes
    }
    .store(in: &cancellables)
```

### Process Output Parsing
```swift
// Real-time progress extraction from yt-dlp output
if line.contains("[download]") && line.contains("%") {
    // Parse progress percentage
    // Update UI with animation
}
```

## User Interface & Workflow

### Application Flow

1. **URL Input**
   - Paste or type URL
   - Automatic clipboard detection
   - Validation and feedback

2. **Metadata Fetch**
   - Quick metadata retrieval
   - Thumbnail preview
   - Format options display

3. **Format Selection**
   - Auto-select best quality
   - Manual format choice
   - Audio-only option

4. **Queue Management**
   - Add to queue
   - Reorder with drag-drop
   - Batch operations

5. **Download Execution**
   - Progress tracking
   - Speed display
   - ETA calculation

6. **Completion**
   - History recording
   - Finder integration
   - Notification

### Panel System

#### Dynamic Panel Visibility
- Panels hide/show with smooth animations
- Auto-adjust based on window size
- Preserve user preferences
- Responsive layout adaptation

#### Keyboard Shortcuts
- `Cmd+V`: Paste and process URL
- `Cmd+,`: Open preferences
- `Space`: Pause/resume selected
- `Delete`: Remove from queue

## System Integration

### yt-dlp Integration
- **Dynamic Binary Location**: Searches multiple paths
- **JSON Communication**: Structured data exchange
- **Progress Parsing**: Real-time output processing
- **Error Handling**: Graceful failure recovery

### ffmpeg Integration
- **Automatic Discovery**: Similar to yt-dlp
- **Format Merging**: Combines video/audio streams
- **Post-Processing**: Thumbnail embedding, conversion
- **Codec Support**: H.264, H.265, VP9, AV1

### Browser Cookie Extraction
Browsers store cookies in different locations and formats:

- **Safari**: ~/Library/Cookies
- **Chrome**: ~/Library/Application Support/Google/Chrome
- **Firefox**: ~/Library/Application Support/Firefox/Profiles
- **Brave**: ~/Library/Application Support/BraveSoftware
- **Edge**: ~/Library/Application Support/Microsoft Edge

### File System Operations
- **Sandboxed Access**: Proper entitlements for file access
- **Path Expansion**: Tilde and variable expansion
- **Permission Handling**: Graceful handling of access errors
- **Finder Integration**: Reveal in Finder functionality

## Development Status

### Current Phase: 4-5 (Production Ready)

#### Implemented Features
- ✅ Core downloading functionality
- ✅ Queue management system
- ✅ Browser cookie support
- ✅ Playlist handling
- ✅ Format selection
- ✅ Progress tracking
- ✅ Preferences system
- ✅ History tracking
- ✅ Debug logging
- ✅ Process management

#### Architecture Principles
1. **Modularity**: Clear separation of concerns
2. **Testability**: Dependency injection ready
3. **Extensibility**: Plugin-ready architecture
4. **Performance**: Efficient resource usage
5. **Security**: Sandboxed, local-only processing

### Future Evolution Plans

#### Phase 6: Enhanced Features
- Scheduled downloads
- Bandwidth management
- Advanced filtering
- Batch URL import

#### Phase 7: Cloud Integration
- Optional cloud storage
- Sync across devices
- Remote queue management

#### Phase 8: AI Integration
- Smart quality selection
- Content categorization
- Automatic metadata enrichment

## Testing & Quality Assurance

### Test Coverage Areas

#### Unit Tests
- URL validation and parsing
- Format selection logic
- Queue management operations
- Preference handling

#### Integration Tests
- yt-dlp communication
- Browser cookie extraction
- File system operations
- Process management

#### UI Tests
- Queue interactions
- Drag and drop
- Panel animations
- Preference changes

### Quality Control
- Continuous testing during development
- Error boundary implementation
- Comprehensive logging system
- Performance monitoring

## Developer Reference

### Building from Source
```bash
# Clone repository
git clone https://github.com/yourusername/yt-dlp-MAX.git

# Open in Xcode
open yt-dlp-MAX.xcodeproj

# Build and run
# Cmd+R in Xcode
```

### Key Patterns to Follow

#### Adding New Features
1. Create service in Services/ directory
2. Define models in Models/
3. Build UI in Views/
4. Connect via @StateObject/@ObservedObject

#### Error Handling
```swift
do {
    try await someOperation()
} catch {
    await MainActor.run {
        statusMessage = "Error: \(error.localizedDescription)"
        DebugLogger.shared.log(error.localizedDescription, level: .error)
    }
}
```

#### Debug Logging
```swift
DebugLogger.shared.log("Operation started", level: .info)
PersistentDebugLogger.shared.log("Persistent message", level: .warning)
```

### Debugging Tools

#### Built-in Debug Console
- Real-time log viewer
- Filter by log level
- Export logs to file
- Clear log history

#### Process Monitor
- View active processes
- Check process status
- Manual termination
- Resource usage

## Security & Privacy

### Security Measures
- **Sandboxed Execution**: App runs in macOS sandbox
- **No Network Tracking**: No analytics or telemetry
- **Local Processing**: All operations on-device
- **Secure Cookie Handling**: Read-only, on-demand access

### Privacy Guarantees
- No user data collection
- No cloud services required
- No third-party integrations
- Open source and auditable

## Licensing & Legal Compliance

### License
Fetcha is distributed under the **GNU General Public License v3.0 (GPL-3.0)** due to its inclusion of GPL-licensed components.

### Why GPL-3.0?
The application bundles FFmpeg binaries that were compiled with GPL-licensed codecs:
- **libx264** (GPL v2+)
- **libx265** (GPL v2+)

According to GPL licensing terms, when GPL-licensed components are bundled with an application, the entire distribution must comply with GPL requirements.

### Bundled Components
1. **FFmpeg** - Licensed under GPL v2+ (due to included codecs)
   - Source: https://github.com/FFmpeg/FFmpeg
   - Used for video/audio processing and format conversion
   
2. **yt-dlp** - Licensed under The Unlicense (public domain)
   - Source: https://github.com/yt-dlp/yt-dlp
   - Used for video metadata extraction and downloading

### GPL Compliance
As required by GPL-3.0:
- Complete source code is available at [repository URL]
- Users have the right to modify and redistribute the software
- Any modifications must also be released under GPL-3.0
- No warranty is provided (see LICENSE file for details)

### FFmpeg Attribution
This software uses code of FFmpeg licensed under the GPLv2+ and its source can be downloaded from https://github.com/FFmpeg/FFmpeg

## Conclusion

Fetcha represents a careful balance between simplicity and power, providing a native Mac experience for media downloading while respecting user privacy and system resources. Its architecture is designed for both current stability and future extensibility, making it a reliable tool for users and a maintainable codebase for developers.

The application embodies the principle that powerful tools don't need to be complicated - they just need to be thoughtfully designed.
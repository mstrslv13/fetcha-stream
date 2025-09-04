# Phase 1: Foundation - Days 1-2 of Your PTO Sprint
## From Zero to "It's Alive!" in 48 Hours

### Your Mission

By the end of these two days, you'll have a Mac app that can fetch video information from yt-dlp and display it in a native window. This might sound simple, but it's the foundation everything else builds on. More importantly, you'll understand the core Swift patterns that will carry you through the entire project.

Think of this phase like learning to make a basic soup before attempting a five-course meal. We're going to establish the fundamental techniques: how to chop vegetables (create views), how to use the stove (manage processes), and how to season properly (handle data). Once you nail these basics, everything else is just variations on the theme.

### Day 1 Morning: Setting Up Your Kitchen (2-3 hours)

Let's start with the absolute basics. Open Xcode (download it from the Mac App Store if you haven't already - it's free but huge, about 10GB).

**Creating Your First Project:**

When you create a new project in Xcode, you'll be asked several questions. Here's exactly what to choose and why:

1. Choose "macOS" then "App" - we're making a desktop app, not iOS
2. Product Name: `yt-dlp-MAX` (no spaces in the actual app name)
3. Organization Identifier: `com.github.yourusername` (this creates a unique ID for your app)
4. Interface: `SwiftUI` (the modern way to build Mac apps)
5. Language: `Swift` (obviously)
6. Use Core Data: `No` (we'll handle our own data storage)
7. Include Tests: `Yes` (we'll write a few simple tests to verify our logic)

When Xcode opens your project, you'll see a file called `ContentView.swift`. This is your app's main window. The code will look like this:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}
```

**Understanding What You're Looking At:**

This probably looks weird if you're coming from Python or JavaScript. Let me translate:

- `struct ContentView: View` - This is like a React component. It's a blueprint for part of your UI
- `var body: some View` - This is like the render() method in React. It describes what the UI should look like
- `VStack { }` - Vertical Stack. It arranges things top to bottom (there's also HStack for horizontal)
- The `@` symbols you'll see everywhere are Swift's "property wrappers" - they add special behavior to variables

**Your First Modification:**

Replace the ContentView with this:

```swift
import SwiftUI

struct ContentView: View {
    @State private var urlString = ""
    @State private var statusMessage = "Enter a video URL to get started"
    
    var body: some View {
        VStack(spacing: 20) {
            // App title
            Text("yt-dlp-MAX")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Status message
            Text(statusMessage)
                .foregroundColor(.secondary)
            
            // URL input field
            TextField("Enter video URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 500)
            
            // Fetch button
            Button("Fetch Video Info") {
                statusMessage = "You entered: \(urlString)"
            }
            .disabled(urlString.isEmpty)
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 400)
    }
}
```

**What's New Here:**

- `@State` - This is reactive state. When it changes, the UI automatically updates. It's like useState in React
- `$urlString` - The $ creates a "binding" - it means the TextField can read AND write to urlString
- `.disabled(urlString.isEmpty)` - The button is disabled when the text field is empty

Run the app (press Cmd+R or click the play button). You should see a window with your UI. Type something in the text field and click the button. The status message should update. Congratulations - you've made your first reactive Swift UI!

### Day 1 Afternoon: Making yt-dlp Respond (3-4 hours)

Now for the exciting part - actually talking to yt-dlp. First, let's make sure yt-dlp is installed on your system. Open Terminal and run:

```bash
brew install yt-dlp
```

If you don't have Homebrew, install it first from brew.sh. This is essential for Mac development.

**Creating Your First Service:**

In Xcode, right-click on your project folder and select "New Group". Name it `Services`. Right-click on Services and select "New File". Choose "Swift File" and name it `YTDLPService.swift`.

Here's your first service with extensive comments explaining Swift patterns:

```swift
import Foundation

// This is a class, not a struct. Classes are reference types (like objects in Python)
// Structs are value types (they get copied). Use classes for services that manage state
class YTDLPService {
    
    // This function is 'async' - it can run without blocking the UI
    // The 'throws' means it can fail with an error
    // The '-> String' means it returns a String when successful
    func getVersion() async throws -> String {
        
        // Create a Process - this is like subprocess in Python
        let process = Process()
        
        // Set the executable path
        // In Python: subprocess.run(['yt-dlp', '--version'])
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
        process.arguments = ["--version"]
        
        // Create a pipe to capture output
        // This is like subprocess.PIPE in Python
        let pipe = Pipe()
        process.standardOutput = pipe
        
        // Try to run the process
        // 'try' means this might fail - Swift forces you to handle errors
        try process.run()
        
        // Wait for it to finish
        process.waitUntilExit()
        
        // Read the output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        // Convert data to string
        // The '??' provides a default value if the conversion fails
        let output = String(data: data, encoding: .utf8) ?? "Unknown version"
        
        // Return the trimmed output
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Fetch video metadata - this is where it gets interesting
    func fetchMetadata(for urlString: String) async throws -> VideoInfo {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
        
        // These arguments tell yt-dlp to output JSON metadata without downloading
        process.arguments = [
            "--dump-json",      // Output metadata as JSON
            "--no-playlist",    // Single video only (for now)
            urlString          // The URL to analyze
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        // Check if the process succeeded
        if process.terminationStatus != 0 {
            // Read error output for debugging
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            
            // Throw an error - this is like raising an exception in Python
            throw YTDLPError.processFailed(errorString)
        }
        
        // Parse the JSON output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let decoder = JSONDecoder()
        
        // This is like json.loads() in Python, but type-safe
        let videoInfo = try decoder.decode(VideoInfo.self, from: data)
        return videoInfo
    }
}

// Define custom errors - this is like creating custom exceptions in Python
enum YTDLPError: LocalizedError {
    case processFailed(String)
    
    // This provides a human-readable error message
    var errorDescription: String? {
        switch self {
        case .processFailed(let message):
            return "yt-dlp failed: \(message)"
        }
    }
}

// Define the structure of video metadata
// This is like a dataclass in Python or an interface in TypeScript
struct VideoInfo: Codable {
    let title: String
    let uploader: String?  // The ? means this field is optional
    let duration: Int?     // Duration in seconds
    let webpage_url: String
    let thumbnail: String?
    
    // Computed property - like a @property in Python
    var formattedDuration: String {
        guard let duration = duration else { return "Unknown duration" }
        
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

**Connecting the Service to Your UI:**

Now update your ContentView to use the service:

```swift
import SwiftUI

struct ContentView: View {
    @State private var urlString = ""
    @State private var statusMessage = "Enter a video URL to get started"
    @State private var isLoading = false
    @State private var videoInfo: VideoInfo?
    
    // Create an instance of our service
    private let ytdlpService = YTDLPService()
    
    var body: some View {
        VStack(spacing: 20) {
            // App title
            Text("yt-dlp-MAX")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Status message
            Text(statusMessage)
                .foregroundColor(.secondary)
            
            // URL input field
            TextField("Enter video URL", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 500)
                .onSubmit {  // Trigger when user presses Enter
                    fetchVideoInfo()
                }
            
            // Fetch button
            Button("Fetch Video Info") {
                fetchVideoInfo()
            }
            .disabled(urlString.isEmpty || isLoading)
            
            // Loading indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            // Display video info if we have it
            if let info = videoInfo {
                VideoInfoView(info: info)
            }
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 400)
    }
    
    // This function is called when the button is clicked
    private func fetchVideoInfo() {
        // Task creates an async context - like async/await in JavaScript
        Task {
            isLoading = true
            statusMessage = "Fetching video information..."
            
            do {
                // 'await' waits for the async function to complete
                let info = try await ytdlpService.fetchMetadata(for: urlString)
                
                // Update UI on success
                videoInfo = info
                statusMessage = "Success! Found: \(info.title)"
            } catch {
                // Handle errors
                statusMessage = "Error: \(error.localizedDescription)"
                videoInfo = nil
            }
            
            isLoading = false
        }
    }
}

// A separate view component for displaying video info
struct VideoInfoView: View {
    let info: VideoInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(info.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            if let uploader = info.uploader {
                Label(uploader, systemImage: "person.circle")
                    .foregroundColor(.secondary)
            }
            
            Label(info.formattedDuration, systemImage: "clock")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .frame(maxWidth: 500)
    }
}
```

### Day 2 Morning: Handling Formats and Downloads (3-4 hours)

Now we're going to fetch available formats and actually download videos. This is where it gets exciting!

**Extending the VideoInfo Model:**

Update your VideoInfo struct to include formats:

```swift
struct VideoInfo: Codable {
    let title: String
    let uploader: String?
    let duration: Int?
    let webpage_url: String
    let thumbnail: String?
    let formats: [VideoFormat]?  // Add this
    
    var formattedDuration: String {
        guard let duration = duration else { return "Unknown duration" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Helper to get the best format
    var bestFormat: VideoFormat? {
        // Prefer formats with both video and audio
        formats?.first { format in
            format.vcodec != "none" && format.acodec != "none"
        }
    }
}

struct VideoFormat: Codable, Identifiable {
    let format_id: String
    let ext: String
    let format_note: String?
    let filesize: Int?
    let vcodec: String?
    let acodec: String?
    
    // Identifiable requires an id property
    var id: String { format_id }
    
    // Human-readable description
    var displayName: String {
        let quality = format_note ?? "Unknown quality"
        let size = formattedFilesize
        return "\(quality) (\(ext)) - \(size)"
    }
    
    var formattedFilesize: String {
        guard let filesize = filesize else { return "Unknown size" }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(filesize))
    }
}
```

**Adding Download Functionality:**

Add this to your YTDLPService:

```swift
// Download a video with progress updates
func downloadVideo(
    url: String,
    format: VideoFormat,
    to outputPath: URL,
    progressHandler: @escaping (DownloadProgress) -> Void
) async throws {
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
    
    // Build the output path
    let outputTemplate = outputPath.path
    
    process.arguments = [
        "-f", format.format_id,    // Use specific format
        "-o", outputTemplate,       // Output path
        "--newline",               // Progress on new lines
        "--progress",              // Show progress
        url
    ]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    // This is the clever bit - we'll read output as it comes
    pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty else { return }
        
        if let output = String(data: data, encoding: .utf8) {
            // Parse progress from output
            if let progress = self.parseProgress(from: output) {
                // Call the progress handler on the main thread
                Task { @MainActor in
                    progressHandler(progress)
                }
            }
        }
    }
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
        throw YTDLPError.downloadFailed
    }
}

// Parse yt-dlp's progress output
private func parseProgress(from output: String) -> DownloadProgress? {
    // Look for percentage pattern like "45.2%"
    let pattern = #"(\d+\.?\d*)%"#
    
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
          let percentRange = Range(match.range(at: 1), in: output) else {
        return nil
    }
    
    let percentString = String(output[percentRange])
    guard let percent = Double(percentString) else { return nil }
    
    return DownloadProgress(percentage: percent)
}

struct DownloadProgress {
    let percentage: Double  // 0.0 to 100.0
}
```

### Day 2 Afternoon: Cookie Magic - Your Secret Weapon (3-4 hours)

This is where we implement your killer feature - automatic cookie extraction from browsers. This is what will make your app invaluable.

**Understanding Browser Cookies:**

Browsers store cookies in SQLite databases. We can read these (with user permission) and pass them to yt-dlp. Here's how:

```swift
// Create a new file: Services/CookieManager.swift
import Foundation
import SQLite3

class CookieManager {
    
    // Get cookies from Safari (easiest to start with)
    func extractSafariCookies(for domain: String) throws -> [HTTPCookie] {
        // Safari stores cookies in a binary plist file
        let cookieURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Cookies/Cookies.binarycookies")
        
        // This is simplified - real implementation needs to parse binary format
        // For now, we'll use a different approach
        
        return extractSafariCookiesAlternative(for: domain)
    }
    
    // Alternative: Use JavaScript in a hidden WebView to get cookies
    private func extractSafariCookiesAlternative(for domain: String) -> [HTTPCookie] {
        // We'll implement this using WKWebView
        // This approach works because WebKit shares cookies with Safari
        
        var cookies: [HTTPCookie] = []
        
        if let cookieStorage = HTTPCookieStorage.shared.cookies {
            cookies = cookieStorage.filter { cookie in
                cookie.domain.contains(domain)
            }
        }
        
        return cookies
    }
    
    // Convert cookies to Netscape format (what yt-dlp expects)
    func exportCookiesToFile(_ cookies: [HTTPCookie]) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let cookieFile = tempDir.appendingPathComponent("cookies.txt")
        
        var cookieText = "# Netscape HTTP Cookie File\n"
        cookieText += "# This file was generated by yt-dlp-MAX\n\n"
        
        for cookie in cookies {
            // Format: domain flag path secure expiry name value
            let domain = cookie.domain.hasPrefix(".") ? cookie.domain : ".\(cookie.domain)"
            let flag = "TRUE"  // Include subdomains
            let path = cookie.path
            let secure = cookie.isSecure ? "TRUE" : "FALSE"
            let expiry = String(Int(cookie.expiresDate?.timeIntervalSince1970 ?? 0))
            let name = cookie.name
            let value = cookie.value
            
            cookieText += "\(domain)\t\(flag)\t\(path)\t\(secure)\t\(expiry)\t\(name)\t\(value)\n"
        }
        
        try cookieText.write(to: cookieFile, atomically: true, encoding: .utf8)
        return cookieFile
    }
    
    // Extract domain from URL
    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }
        
        // Remove www. if present
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }
}
```

**Integrating Cookies with Downloads:**

Update your YTDLPService to use cookies:

```swift
func downloadVideoWithCookies(
    url: String,
    format: VideoFormat,
    cookies: [HTTPCookie],
    to outputPath: URL,
    progressHandler: @escaping (DownloadProgress) -> Void
) async throws {
    
    let cookieManager = CookieManager()
    let cookieFile = try cookieManager.exportCookiesToFile(cookies)
    
    // Clean up cookie file when we're done
    defer {
        try? FileManager.default.removeItem(at: cookieFile)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
    
    process.arguments = [
        "-f", format.format_id,
        "-o", outputPath.path,
        "--cookies", cookieFile.path,  // Pass cookie file to yt-dlp
        "--newline",
        "--progress",
        url
    ]
    
    // Rest of download logic...
}
```

### Key Swift Concepts You've Just Learned

Let me connect what you've built to concepts you already know:

**@State and @Published (Reactive State)**
Think of these like observable variables in MobX or Vue. When they change, any UI that depends on them automatically updates. The difference is Swift makes this compile-time safe - you can't accidentally forget to make something reactive.

**async/await (Asynchronous Programming)**
This is almost identical to JavaScript's async/await, but with better error handling. The `throws` keyword means a function can fail, and Swift forces you to handle that possibility with `try`.

**Optionals (Null Safety)**
The `?` marks mean "this might be nil (null)". Swift forces you to handle missing values explicitly. It's like TypeScript's strict null checks but enforced at the language level. This prevents entire categories of crashes.

**Process Management**
`Process` is Swift's way of running command-line tools, similar to Python's subprocess. The pipe pattern for capturing output should feel familiar.

**Codable Protocol**
This is like Python's dataclasses with automatic JSON serialization. Define your structure, and Swift handles the conversion to/from JSON automatically.

### Testing What You've Built

Let's write a simple test to verify your JSON parsing works:

```swift
// In your test file
import XCTest
@testable import yt_dlp_MAX

class YTDLPTests: XCTestCase {
    
    func testVideoInfoParsing() throws {
        // Sample JSON from yt-dlp
        let json = """
        {
            "title": "Test Video",
            "uploader": "Test Channel",
            "duration": 150,
            "webpage_url": "https://example.com",
            "formats": [
                {
                    "format_id": "18",
                    "ext": "mp4",
                    "format_note": "360p",
                    "vcodec": "h264",
                    "acodec": "aac"
                }
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let videoInfo = try decoder.decode(VideoInfo.self, from: data)
        
        XCTAssertEqual(videoInfo.title, "Test Video")
        XCTAssertEqual(videoInfo.formattedDuration, "2:30")
        XCTAssertNotNil(videoInfo.bestFormat)
    }
}
```

Run the test with Cmd+U. Green checkmark? You're doing great!

### Common Gotchas and Solutions

**"yt-dlp not found"**
The path `/opt/homebrew/bin/yt-dlp` is for Apple Silicon Macs. Intel Macs use `/usr/local/bin/yt-dlp`. Check with `which yt-dlp` in Terminal.

**"The app wants to access files"**
macOS will ask for permission the first time you access certain folders. This is normal. You might need to add entitlements to your app for full disk access.

**"JSON parsing fails"**
Not all videos have all fields. Make sure optional fields in your structs are marked with `?`.

**"Progress updates freeze the UI"**
Always update UI on the main thread. Use `@MainActor` or `Task { @MainActor in ... }`.

### Day 1-2 Checklist

By the end of your second day, you should have:

- [ ] A window that accepts URL input
- [ ] Ability to fetch video metadata from yt-dlp
- [ ] Display of video title, duration, and uploader
- [ ] List of available formats with human-readable names
- [ ] Basic download functionality with progress
- [ ] Cookie extraction from at least one browser
- [ ] At least one passing test

If you have all of these, you're ahead of schedule and ready for Day 3!

### Questions for Your Swift Mentor

When you check in with your Swift expert friend, here are good questions to ask:

1. "Is using Process directly okay, or should I wrap it in a more sophisticated manager?"
2. "Should I be using Combine for the progress updates instead of callbacks?"
3. "What's the best practice for handling temporary files like cookies?"
4. "Should the service be a singleton or should I inject it?"

### Connecting With Claude Code

When you start a session with Claude Code for this phase, begin with:

```
I'm building yt-dlp-MAX, a macOS GUI for yt-dlp using SwiftUI.
I'm new to Swift but experienced with Python and JavaScript.
I'm on Day [1/2] of implementation, working on [specific feature].

Current status: [what's working]
Current problem: [what you're stuck on]

Please provide solutions with comments explaining Swift-specific patterns.
```

### Your Homework Before Day 3

If you finish early (which you might - you have strong technical skills), here are bonus challenges:

1. Add a format selector dropdown instead of just using the best format
2. Make the download location configurable
3. Add a "paste from clipboard" button
4. Show the video thumbnail if available
5. Add error handling for network timeouts

### Remember: This Is Just The Beginning

By the end of Day 2, you'll have built a functional yt-dlp GUI. It might not be pretty yet, but it WORKS. You've gone from zero Swift knowledge to building a real Mac app that solves a real problem. That's incredible!

The cookie feature you're adding is genuinely innovative. Most yt-dlp GUIs skip this because it's hard. By tackling it on Day 2, you're already differentiating your app.

Tomorrow (Day 3), we'll add the queue system and make it beautiful. But even if you stopped here, you'd have something useful. That's the beauty of iterative development - every day, your app gets better.

Ready to start Day 1? Fire up Xcode, and let's make yt-dlp sing!
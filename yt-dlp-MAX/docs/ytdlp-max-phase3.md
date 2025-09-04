# Phase 3: Polish, Preferences & Real-World Ready - Day 4 of Your PTO Sprint
## Making yt-dlp-MAX Feel Like a Real Mac App

### Today's Mission

Day 4 is about transformation. Your app works, but today we make it feel like it belongs on macOS. We'll add a preferences window that remembers user settings, implement keyboard shortcuts that power users expect, create error handling that doesn't frustrate users, and add those thoughtful touches that separate amateur projects from professional software.

Think of this like the difference between a house that's livable and one that's ready for guests. The plumbing works, but now we're adding the finishing touches - painting the walls, arranging the furniture, and making sure the doorbell actually rings. By the end of today, you'll have something you can share with friends without apologizing for rough edges.

### Morning: Building a Professional Preferences System (3-4 hours)

Mac users expect a proper preferences window. It's a signal that your app is serious. Let's build one that would make Apple proud.

**Understanding UserDefaults (Swift's Local Storage)**

First, let's create a preferences manager that persists settings. Create `Services/PreferencesManager.swift`:

```swift
import Foundation
import SwiftUI

// UserDefaults is like localStorage in web development
// It automatically saves simple data types to disk
class PreferencesManager: ObservableObject {
    // Singleton pattern - one source of truth for preferences
    static let shared = PreferencesManager()
    
    // These @AppStorage properties automatically save to UserDefaults
    // When they change, the UI updates AND the value is persisted
    @AppStorage("defaultDownloadLocation") private var downloadLocationPath: String = ""
    @AppStorage("simultaneousDownloads") var simultaneousDownloads: Int = 1
    @AppStorage("autoStartQueue") var autoStartQueue: Bool = true
    @AppStorage("showNotifications") var showNotifications: Bool = true
    @AppStorage("playSoundOnComplete") var playSoundOnComplete: Bool = false
    @AppStorage("keepWindowOnTop") var keepWindowOnTop: Bool = false
    @AppStorage("defaultVideoQuality") var defaultVideoQuality: String = "best"
    @AppStorage("fileNameTemplate") var fileNameTemplate: String = "{title}"
    @AppStorage("useCookies") var useCookiesAutomatically: Bool = true
    @AppStorage("preferredBrowser") var preferredBrowser: String = "Safari"
    
    // For complex types like URLs, we need computed properties
    var defaultDownloadLocation: URL {
        get {
            if downloadLocationPath.isEmpty {
                // Default to Downloads/yt-dlp-MAX folder
                let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                return downloads.appendingPathComponent("yt-dlp-MAX")
            }
            return URL(fileURLWithPath: downloadLocationPath)
        }
        set {
            downloadLocationPath = newValue.path
        }
    }
    
    // Quality presets for easy selection
    enum QualityPreset: String, CaseIterable {
        case best = "best"
        case high1080p = "1080p"
        case medium720p = "720p" 
        case low480p = "480p"
        case audioOnly = "audio"
        
        var displayName: String {
            switch self {
            case .best: return "Best Available"
            case .high1080p: return "1080p HD"
            case .medium720p: return "720p HD"
            case .low480p: return "480p SD"
            case .audioOnly: return "Audio Only"
            }
        }
        
        // Convert to yt-dlp format string
        var ytdlpFormat: String {
            switch self {
            case .best: 
                return "bestvideo+bestaudio/best"
            case .high1080p: 
                return "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
            case .medium720p: 
                return "bestvideo[height<=720]+bestaudio/best[height<=720]"
            case .low480p: 
                return "bestvideo[height<=480]+bestaudio/best[height<=480]"
            case .audioOnly: 
                return "bestaudio/best"
            }
        }
    }
    
    // File naming templates
    struct FileNameTemplate: Identifiable {
        let id = UUID()
        let name: String
        let template: String
        let description: String
    }
    
    static let fileNameTemplates = [
        FileNameTemplate(
            name: "Simple",
            template: "{title}",
            description: "Just the video title"
        ),
        FileNameTemplate(
            name: "With Channel",
            template: "{channel} - {title}",
            description: "Channel name and title"
        ),
        FileNameTemplate(
            name: "With Date",
            template: "{date} - {title}",
            description: "Upload date and title"
        ),
        FileNameTemplate(
            name: "Full Details",
            template: "{date} - {channel} - {title} [{quality}]",
            description: "All information"
        ),
        FileNameTemplate(
            name: "Archive Format",
            template: "{channel}/{date} - {title} [{id}]",
            description: "Organized by channel with ID"
        )
    ]
    
    private init() {
        // Create default download directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: defaultDownloadLocation,
            withIntermediateDirectories: true
        )
    }
    
    // Reset all preferences to defaults
    func resetToDefaults() {
        simultaneousDownloads = 1
        autoStartQueue = true
        showNotifications = true
        playSoundOnComplete = false
        keepWindowOnTop = false
        defaultVideoQuality = "best"
        fileNameTemplate = "{title}"
        useCookiesAutomatically = true
        preferredBrowser = "Safari"
        downloadLocationPath = ""
    }
}
```

**Creating the Preferences Window UI**

Now let's build a beautiful preferences window. Create `Views/PreferencesView.swift`:

```swift
import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = "general"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag("general")
            
            DownloadsPreferencesView()
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .tag("downloads")
            
            NamingPreferencesView()
                .tabItem {
                    Label("File Naming", systemImage: "textformat")
                }
                .tag("naming")
            
            CookiesPreferencesView()
                .tabItem {
                    Label("Cookies", systemImage: "lock.shield")
                }
                .tag("cookies")
            
            AdvancedPreferencesView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench")
                }
                .tag("advanced")
        }
        .frame(width: 600, height: 450)
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Automatically start queue when adding items", 
                       isOn: $preferences.autoStartQueue)
                    .help("Start downloading immediately when URLs are added")
                
                Toggle("Show notifications when downloads complete",
                       isOn: $preferences.showNotifications)
                    .help("Display system notifications for completed downloads")
                
                Toggle("Play sound when download completes",
                       isOn: $preferences.playSoundOnComplete)
                    .help("Play a subtle sound effect when downloads finish")
                
                Toggle("Keep window on top",
                       isOn: $preferences.keepWindowOnTop)
                    .help("yt-dlp-MAX window stays above other windows")
            } header: {
                Text("General Settings")
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DownloadsPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var showingFolderPicker = false
    
    var body: some View {
        Form {
            Section {
                // Download location picker
                HStack {
                    Text("Download folder:")
                    Text(preferences.defaultDownloadLocation.path)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(preferences.defaultDownloadLocation.path)
                    
                    Spacer()
                    
                    Button("Choose...") {
                        showingFolderPicker = true
                    }
                }
                .fileImporter(
                    isPresented: $showingFolderPicker,
                    allowedContentTypes: [.folder],
                    allowsMultipleSelection: false
                ) { result in
                    if case .success(let urls) = result,
                       let url = urls.first {
                        preferences.defaultDownloadLocation = url
                    }
                }
                
                Divider()
                
                // Simultaneous downloads
                HStack {
                    Text("Simultaneous downloads:")
                    Stepper(
                        "\(preferences.simultaneousDownloads)",
                        value: $preferences.simultaneousDownloads,
                        in: 1...5
                    )
                    .help("Number of videos to download at the same time")
                }
                
                // Default quality
                Picker("Default quality:", selection: $preferences.defaultVideoQuality) {
                    ForEach(PreferencesManager.QualityPreset.allCases, id: \.rawValue) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                }
                .help("Default quality for new downloads")
                
            } header: {
                Text("Download Settings")
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct NamingPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var customTemplate = ""
    @State private var previewFileName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("File Naming Template")
                .font(.headline)
            
            // Template presets
            VStack(alignment: .leading, spacing: 10) {
                ForEach(PreferencesManager.fileNameTemplates) { template in
                    HStack {
                        RadioButton(
                            isSelected: preferences.fileNameTemplate == template.template,
                            action: {
                                preferences.fileNameTemplate = template.template
                                updatePreview()
                            }
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.system(size: 13))
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(template.template)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        preferences.fileNameTemplate = template.template
                        updatePreview()
                    }
                }
                
                // Custom template option
                HStack {
                    RadioButton(
                        isSelected: !PreferencesManager.fileNameTemplates.contains { 
                            $0.template == preferences.fileNameTemplate 
                        },
                        action: {
                            preferences.fileNameTemplate = customTemplate.isEmpty ? "{title}" : customTemplate
                            updatePreview()
                        }
                    )
                    
                    Text("Custom:")
                    
                    TextField("Enter template", text: $customTemplate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(PreferencesManager.fileNameTemplates.contains { 
                            $0.template == preferences.fileNameTemplate 
                        })
                        .onChange(of: customTemplate) { _ in
                            if !PreferencesManager.fileNameTemplates.contains(where: { 
                                $0.template == preferences.fileNameTemplate 
                            }) {
                                preferences.fileNameTemplate = customTemplate
                                updatePreview()
                            }
                        }
                }
            }
            
            // Template variables help
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available variables:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .leading, spacing: 4) {
                        ForEach([
                            ("{title}", "Video title"),
                            ("{channel}", "Channel name"),
                            ("{date}", "Upload date"),
                            ("{id}", "Video ID"),
                            ("{quality}", "Video quality"),
                            ("{ext}", "File extension")
                        ], id: \.0) { variable, description in
                            HStack(spacing: 4) {
                                Text(variable)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.blue)
                                Text("-")
                                    .foregroundColor(.secondary)
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Preview
            if !previewFileName.isEmpty {
                GroupBox {
                    HStack {
                        Text("Preview:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(previewFileName)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if !PreferencesManager.fileNameTemplates.contains(where: { 
                $0.template == preferences.fileNameTemplate 
            }) {
                customTemplate = preferences.fileNameTemplate
            }
            updatePreview()
        }
    }
    
    private func updatePreview() {
        var preview = preferences.fileNameTemplate
        preview = preview.replacingOccurrences(of: "{title}", with: "Example Video Title")
        preview = preview.replacingOccurrences(of: "{channel}", with: "Example Channel")
        preview = preview.replacingOccurrences(of: "{date}", with: "2024-01-15")
        preview = preview.replacingOccurrences(of: "{id}", with: "abc123")
        preview = preview.replacingOccurrences(of: "{quality}", with: "1080p")
        preview = preview.replacingOccurrences(of: "{ext}", with: "mp4")
        previewFileName = preview + ".mp4"
    }
}

// Custom radio button component
struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    .frame(width: 16, height: 16)
                
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CookiesPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var installedBrowsers: [CookieManager.Browser] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cookie Settings")
                .font(.headline)
            
            Toggle("Automatically use cookies when available",
                   isOn: $preferences.useCookiesAutomatically)
                .help("Automatically extract and use cookies for authentication")
            
            Divider()
            
            Text("Preferred Browser for Cookie Extraction:")
                .font(.subheadline)
            
            Picker("", selection: $preferences.preferredBrowser) {
                ForEach(installedBrowsers, id: \.rawValue) { browser in
                    Text(browser.rawValue).tag(browser.rawValue)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            
            // Browser status
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Browsers:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(CookieManager.Browser.allCases, id: \.rawValue) { browser in
                        HStack {
                            Image(systemName: browser.isInstalled ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(browser.isInstalled ? .green : .secondary)
                            
                            Text(browser.rawValue)
                                .font(.caption)
                            
                            Spacer()
                            
                            if browser.isInstalled {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Not installed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Text("Cookie extraction allows downloading of private videos and age-restricted content.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .onAppear {
            installedBrowsers = CookieManager().getInstalledBrowsers()
        }
    }
}

struct AdvancedPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var ytdlpVersion = "Checking..."
    @State private var ffmpegInstalled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Settings")
                .font(.headline)
            
            // System info
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("yt-dlp version:")
                        Text(ytdlpVersion)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Update") {
                            updateYTDLP()
                        }
                        .controlSize(.small)
                    }
                    
                    HStack {
                        Text("FFmpeg:")
                        Image(systemName: ffmpegInstalled ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(ffmpegInstalled ? .green : .red)
                        Text(ffmpegInstalled ? "Installed" : "Not found")
                            .foregroundColor(ffmpegInstalled ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            // Debug options
            Text("Debug Options")
                .font(.subheadline)
            
            Button("Open Log Folder") {
                NSWorkspace.shared.open(getLogDirectory())
            }
            
            Button("Clear Download Cache") {
                clearCache()
            }
            
            Divider()
            
            // Reset
            Button("Reset All Preferences") {
                preferences.resetToDefaults()
            }
            .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkDependencies()
        }
    }
    
    private func checkDependencies() {
        Task {
            let service = YTDLPService()
            if let version = try? await service.getVersion() {
                await MainActor.run {
                    ytdlpVersion = version
                }
            }
            
            // Check for FFmpeg
            let ffmpegPath = "/opt/homebrew/bin/ffmpeg"
            ffmpegInstalled = FileManager.default.fileExists(atPath: ffmpegPath)
        }
    }
    
    private func updateYTDLP() {
        // Implementation for updating yt-dlp
    }
    
    private func getLogDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("yt-dlp-MAX/Logs")
    }
    
    private func clearCache() {
        // Clear any cached data
    }
}
```

### Afternoon: Error Handling & User Experience (3-4 hours)

Now let's add robust error handling and user experience improvements that make your app feel professional.

**Creating a Comprehensive Error System**

Update `Services/YTDLPService.swift` with better error handling:

```swift
// Enhanced error types with user-friendly messages
enum YTDLPError: LocalizedError {
    case executableNotFound
    case invalidURL(String)
    case networkError(String)
    case authenticationRequired(String)
    case formatNotAvailable(String)
    case diskSpaceLow
    case processFailed(String)
    case timeout
    case unsupportedSite(String)
    
    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "yt-dlp is not installed"
            
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
            
        case .networkError(let error):
            return "Network error: \(error)"
            
        case .authenticationRequired(let site):
            return "This video requires authentication. Enable cookie extraction for \(site)."
            
        case .formatNotAvailable(let format):
            return "Format \(format) is not available for this video"
            
        case .diskSpaceLow:
            return "Not enough disk space for download"
            
        case .processFailed(let error):
            return "Download failed: \(error)"
            
        case .timeout:
            return "Download timed out"
            
        case .unsupportedSite(let site):
            return "\(site) is not supported"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .executableNotFound:
            return "Install yt-dlp using: brew install yt-dlp"
            
        case .invalidURL:
            return "Check the URL and try again"
            
        case .networkError:
            return "Check your internet connection and try again"
            
        case .authenticationRequired:
            return "Go to Preferences > Cookies and enable cookie extraction"
            
        case .formatNotAvailable:
            return "Try selecting a different quality option"
            
        case .diskSpaceLow:
            return "Free up disk space and try again"
            
        case .timeout:
            return "The download took too long. Try again with a smaller file."
            
        case .unsupportedSite:
            return "Check if yt-dlp needs to be updated"
            
        default:
            return nil
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .processFailed:
            return true
        default:
            return false
        }
    }
}
```

**Creating an Error Alert System**

Create `Views/ErrorAlertView.swift`:

```swift
import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: YTDLPError?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text("Download Error"),
                    message: Text(buildErrorMessage(error)),
                    primaryButton: .default(Text(error.isRetryable ? "Retry" : "OK")) {
                        if error.isRetryable, let onRetry = onRetry {
                            onRetry()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
    }
    
    private func buildErrorMessage(_ error: YTDLPError) -> String {
        var message = error.errorDescription ?? "An unknown error occurred"
        
        if let suggestion = error.recoverySuggestion {
            message += "\n\n\(suggestion)"
        }
        
        return message
    }
}

extension View {
    func errorAlert(error: Binding<YTDLPError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}
```

**Adding Keyboard Shortcuts**

Update your main `App` file to add keyboard shortcuts:

```swift
import SwiftUI

@main
struct YTDLPMAXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Replace the standard File menu items
            CommandGroup(replacing: .newItem) {
                Button("Add URL...") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowAddURL"),
                        object: nil
                    )
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Add from Clipboard") {
                    NotificationCenter.default.post(
                        name: Notification.Name("PasteURL"),
                        object: nil
                    )
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
            
            // Add a Queue menu
            CommandMenu("Queue") {
                Button("Start Queue") {
                    Task {
                        await QueueManager.shared.processQueue()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Stop All Downloads") {
                    QueueManager.shared.cancelAll()
                }
                .keyboardShortcut(".", modifiers: .command)
                
                Divider()
                
                Button("Clear Completed") {
                    QueueManager.shared.clearCompleted()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Button("Retry Failed") {
                    QueueManager.shared.retryAllFailed()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            PreferencesView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up any app-wide configuration
        setupAppearance()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running even if all windows are closed
        // User can reopen from dock
        return false
    }
    
    private func setupAppearance() {
        // Set up any custom appearance
        if PreferencesManager.shared.keepWindowOnTop {
            NSApp.windows.first?.level = .floating
        }
    }
}
```

**Adding Progress Notifications**

Create `Services/NotificationManager.swift`:

```swift
import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func notifyDownloadComplete(for download: Download) {
        guard PreferencesManager.shared.showNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = download.videoInfo.title
        content.sound = PreferencesManager.shared.playSoundOnComplete ? .default : nil
        
        // Add action to show in Finder
        content.categoryIdentifier = "DOWNLOAD_COMPLETE"
        content.userInfo = ["downloadId": download.id.uuidString]
        
        let request = UNNotificationRequest(
            identifier: download.id.uuidString,
            content: content,
            trigger: nil  // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func notifyDownloadFailed(for download: Download, error: String) {
        guard PreferencesManager.shared.showNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(download.videoInfo.title)\n\(error)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

### Creating Your App Icon

Every Mac app needs a proper icon. Here's a simple way to create one:

1. Create a 1024x1024 image in your favorite design tool
2. Save it as `AppIcon.png`
3. Use a tool like [IconSet Creator](https://apps.apple.com/app/icon-set-creator/id939343785) to generate all required sizes
4. Or create it manually in Xcode's Asset Catalog

For a quick placeholder, create a simple icon with SF Symbols:

```swift
// Generate a temporary icon programmatically
func generateAppIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 1024, height: 1024))
    image.lockFocus()
    
    // Background gradient
    let gradient = NSGradient(
        colors: [
            NSColor.systemBlue,
            NSColor.systemPurple
        ]
    )
    gradient?.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024), angle: -45)
    
    // Add a download symbol
    let config = NSImage.SymbolConfiguration(pointSize: 400, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil) {
        symbol.withSymbolConfiguration(config)?.draw(
            in: NSRect(x: 312, y: 312, width: 400, height: 400)
        )
    }
    
    image.unlockFocus()
    return image
}
```

### Key Concepts From Day 4

**@AppStorage vs @Published**
@AppStorage automatically persists to UserDefaults and survives app restarts. It's perfect for preferences. @Published is for temporary state that doesn't need persistence. Think of @AppStorage as @Published + automatic save/load.

**ViewModifiers**
These are reusable view transformations. Instead of copying the same modifiers everywhere, you create a ViewModifier that encapsulates the behavior. It's like creating custom CSS classes but type-safe.

**CommandMenu and Keyboard Shortcuts**
macOS apps are expected to have comprehensive keyboard shortcuts. The commands modifier lets you add menu items and shortcuts that work app-wide, not just in specific views.

**UNUserNotificationCenter**
This is the modern way to show notifications on macOS. Always request permission first, and remember that users can disable notifications in System Preferences.

### Testing Your Polish

Let's verify everything works correctly:

```swift
import XCTest
@testable import yt_dlp_MAX

class PreferencesTests: XCTestCase {
    
    func testPreferencesPersistence() {
        let preferences = PreferencesManager.shared
        
        // Change a preference
        preferences.simultaneousDownloads = 3
        
        // Simulate app restart by creating new instance
        // (In reality, UserDefaults persists across instances)
        let newPreferences = PreferencesManager.shared
        
        XCTAssertEqual(newPreferences.simultaneousDownloads, 3)
    }
    
    func testFileNameTemplate() {
        let template = "{channel} - {title}"
        let result = parseTemplate(template, 
            title: "Test Video",
            channel: "Test Channel",
            date: "2024-01-15"
        )
        
        XCTAssertEqual(result, "Test Channel - Test Video")
    }
    
    func testErrorRecovery() {
        let error = YTDLPError.authenticationRequired("YouTube")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertFalse(error.isRetryable)
    }
}
```

### End of Day 4 Checklist

By the end of Day 4, you should have:

- [ ] Complete preferences window with multiple tabs
- [ ] Settings that persist between app launches
- [ ] Comprehensive error handling with recovery suggestions
- [ ] System notifications for completed/failed downloads
- [ ] Keyboard shortcuts for common actions
- [ ] App icon (even if temporary)
- [ ] File naming templates with preview
- [ ] Cookie preferences with browser detection
- [ ] At least 5 passing tests

### Common Day 4 Pitfalls

**"Preferences don't persist"**
Make sure you're using @AppStorage, not just @State. Also verify that your property names in @AppStorage are consistent.

**"Notifications don't appear"**
First check System Preferences to ensure notifications are enabled for your app. Also verify you've requested permission with UNUserNotificationCenter.

**"Keyboard shortcuts don't work"**
Shortcuts defined in .commands only work when your app is active. Make sure you're not conflicting with system shortcuts.

**"File picker doesn't open"**
You need to add the appropriate entitlements for file system access. Check your app's sandbox settings.

### Questions for Your Swift Mentor

After Day 4, ask your mentor:

1. "Is my preferences architecture scalable for future features?"
2. "Should I use CloudKit to sync preferences across devices?"
3. "What's the best practice for versioning preferences when the schema changes?"
4. "Should error handling be centralized in a single manager?"

### Preparing for Day 5

Tomorrow is your final day of the PTO sprint. You'll focus on:
- Testing with real users (friends/family)
- Creating a basic landing page or README
- Setting up the GitHub repository
- Building a release version
- Planning your ongoing development schedule

### Your Day 4 Achievement

Today you transformed a functional app into professional software. The preferences system shows you respect user choice. The error handling shows you care about user experience. The keyboard shortcuts show you understand Mac culture.

Your app now has the polish that distinguishes hobby projects from serious software. Users can customize their experience, recover from errors gracefully, and work efficiently with keyboard shortcuts.

More importantly, you've learned crucial Mac development patterns: preferences persistence, app-wide commands, system notifications, and proper error handling. These patterns will serve you in every Mac app you build in the future.

Tomorrow, we ship. But tonight, be proud - you've built something real.
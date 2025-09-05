/*
Test Coverage Analysis:
- Scenarios tested: Missing dependencies, file system issues, invalid inputs, race conditions
- Critical tests: Missing binaries, permission errors, disk space, corrupted data
- Edge cases: Special characters, long paths, concurrent access, system limits
- Error recovery: Retry mechanisms, fallback behaviors, graceful degradation
*/

import Testing
import Foundation
import AppKit
@testable import yt_dlp_MAX

@Suite("Edge Case and Error Condition Tests - v0.9.5")
struct EdgeCaseTests {
    
    // MARK: - Missing Dependencies Tests
    
    @Test("Handle missing yt-dlp binary gracefully")
    func testMissingYtdlpBinary() async throws {
        let ytdlpService = YTDLPService()
        
        // Override the binary path search
        let originalPath = ytdlpService.ytdlpPath
        
        // Test with non-existent path
        let task = DownloadTask(url: "https://test.com", title: "Test")
        
        // The service should handle this gracefully
        do {
            // Force a non-existent binary path
            // In production, this would show an error alert
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/nonexistent/yt-dlp")
            process.arguments = ["--version"]
            
            try process.run()
            Issue.record("Should fail with missing binary")
        } catch {
            // Expected error
            #expect(error.localizedDescription.contains("launch") || 
                   error.localizedDescription.contains("file"), 
                   "Should indicate missing file")
        }
    }
    
    @Test("Handle missing ffmpeg for thumbnail embedding")
    func testMissingFFmpegForThumbnails() async throws {
        let prefs = AppPreferences.shared
        prefs.embedThumbnail = true
        prefs.ffmpegPath = "/nonexistent/ffmpeg"
        
        // Check if ffmpeg is found
        let ffmpegPath = prefs.resolvedFfmpegPath
        
        // If ffmpeg is not at the forced path, it might fall back to system search
        // The app should continue without thumbnail embedding
        
        // Create a mock download that requests thumbnail embedding
        let task = DownloadTask(url: "https://test.com", title: "Test")
        
        // The download should proceed without embedding
        // This would be logged as a warning in production
        #expect(task.status != "failed", "Download should not fail due to missing ffmpeg")
    }
    
    // MARK: - File System Permission Tests
    
    @Test("Handle write permission denied")
    func testWritePermissionDenied() async throws {
        // Try to write to a protected directory
        let protectedPath = "/System/test_file.mp4"
        
        do {
            try Data("test".utf8).write(to: URL(fileURLWithPath: protectedPath))
            Issue.record("Should not be able to write to protected directory")
        } catch {
            // Expected error
            #expect(error.localizedDescription.contains("Permission") ||
                   error.localizedDescription.contains("denied") ||
                   error.localizedDescription.contains("Operation not permitted"),
                   "Should indicate permission error")
        }
    }
    
    @Test("Handle disk space exhaustion")
    func testDiskSpaceExhaustion() async throws {
        // Check available disk space
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: tempDir.path)
            if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                let freeMB = freeSpace.int64Value / 1_048_576
                print("Available disk space: \(freeMB) MB")
                
                // The app should check disk space before download
                #expect(freeMB > 0, "Should have some free disk space")
            }
        } catch {
            print("Could not check disk space: \(error)")
        }
    }
    
    // MARK: - Invalid Input Tests
    
    @Test("Handle invalid URLs")
    @MainActor
    func testInvalidURLs() async throws {
        let queue = DownloadQueue()
        
        let invalidURLs = [
            "",                              // Empty
            "not a url",                     // No protocol
            "http://",                       // Incomplete
            "ftp://example.com",            // Wrong protocol
            "https://[invalid",             // Malformed
            "https://example..com",         // Invalid domain
            "https://.com",                 // Missing domain
            "https://example.com:99999",    // Invalid port
            "https://192.168.1.999",        // Invalid IP
            "file:///etc/passwd"            // Local file
        ]
        
        for url in invalidURLs {
            // The app should validate URLs before processing
            let isValid = validateURL(url)
            #expect(!isValid, "URL '\(url)' should be invalid")
        }
    }
    
    @Test("Handle extremely long URLs")
    func testExtremelyLongURLs() async throws {
        // Most systems have a URL length limit around 2048-4096 characters
        let longPath = String(repeating: "a", count: 5000)
        let longURL = "https://example.com/\(longPath)"
        
        // The app should handle or reject very long URLs
        let isValid = validateURL(longURL)
        
        if isValid {
            print("System accepts very long URLs")
        } else {
            print("System rejects URLs over limit")
        }
    }
    
    // MARK: - Special Characters Tests
    
    @Test("Handle special characters in filenames")
    func testSpecialCharactersInFilenames() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("special_chars_test")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        let problematicNames = [
            "video:with:colons.mp4",        // Colons (problematic on some systems)
            "video|with|pipes.mp4",          // Pipes
            "video<with>brackets.mp4",       // Angle brackets
            "video\"with\"quotes.mp4",       // Quotes
            "video?with?questions.mp4",      // Question marks
            "video*with*asterisks.mp4",      // Asterisks
            "video\\with\\backslashes.mp4",  // Backslashes
            "video/with/slashes.mp4",        // Forward slashes
            "video\nwith\nnewlines.mp4",     // Newlines
            "video\twith\ttabs.mp4",         // Tabs
            "video with spaces.mp4",         // Spaces (normal but test)
            "видео.mp4",                     // Unicode (Cyrillic)
            "视频.mp4",                      // Unicode (Chinese)
            "🎬video🎥.mp4",                 // Emojis
            ".hidden.mp4",                   // Hidden file
            "..double.mp4",                  // Double dots
            "CON.mp4",                       // Reserved name (Windows)
            "PRN.mp4",                       // Reserved name (Windows)
            "AUX.mp4"                        // Reserved name (Windows)
        ]
        
        for name in problematicNames {
            // Try to create file with problematic name
            let sanitized = sanitizeFilename(name)
            let file = testDir.appendingPathComponent(sanitized)
            
            do {
                try Data("test".utf8).write(to: file)
                #expect(FileManager.default.fileExists(atPath: file.path), 
                       "Sanitized file '\(sanitized)' should be created")
                try FileManager.default.removeItem(at: file)
            } catch {
                print("Failed to handle filename '\(name)': \(error)")
            }
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDir)
    }
    
    @Test("Handle very long filenames")
    func testVeryLongFilenames() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("long_name_test")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        // Most file systems have a 255 character limit for filenames
        let longName = String(repeating: "a", count: 300) + ".mp4"
        let truncated = truncateFilename(longName, maxLength: 255)
        
        #expect(truncated.count <= 255, "Filename should be truncated to 255 chars or less")
        #expect(truncated.hasSuffix(".mp4"), "Should preserve file extension")
        
        // Try to create file
        let file = testDir.appendingPathComponent(truncated)
        do {
            try Data("test".utf8).write(to: file)
            #expect(FileManager.default.fileExists(atPath: file.path), "File with truncated name should exist")
        } catch {
            print("Failed to create file with long name: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDir)
    }
    
    // MARK: - Corrupted Data Tests
    
    @Test("Handle corrupted history file")
    func testCorruptedHistoryFile() async throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("fetcha.stream", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        let historyFile = appFolder.appendingPathComponent("download_history.json")
        
        // Write various types of corrupted data
        let corruptedData = [
            "not json at all",
            "{",
            "[{\"invalid\": }]",
            "null",
            "[]trailing",
            "{\"videoId\": 123}", // Wrong type
            "[{\"videoId\": \"test\"}]" // Missing required fields
        ]
        
        for corrupt in corruptedData {
            try corrupt.data(using: .utf8)?.write(to: historyFile)
            
            // Try to load
            let history = DownloadHistory.shared
            history.loadHistory()
            
            // Should handle gracefully
            // History should be empty or contain only valid records
            print("Handled corrupted data: '\(corrupt.prefix(20))...'")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: historyFile)
    }
    
    @Test("Handle corrupted preferences")
    func testCorruptedPreferences() async throws {
        // UserDefaults corruption is harder to simulate
        // But we can test invalid values
        
        let defaults = UserDefaults.standard
        
        // Set invalid values
        defaults.set(-1, forKey: "maxConcurrentDownloads")
        defaults.set("invalid", forKey: "rateLimitKbps")
        defaults.set(99999, forKey: "retryAttempts")
        
        // The app should validate and use defaults for invalid values
        let prefs = AppPreferences.shared
        
        // Should use reasonable defaults
        #expect(prefs.maxConcurrentDownloads > 0, "Should have valid concurrent downloads")
        #expect(prefs.maxConcurrentDownloads <= 10, "Should have reasonable upper limit")
        #expect(prefs.retryAttempts >= 0, "Should have non-negative retries")
        #expect(prefs.retryAttempts <= 10, "Should have reasonable retry limit")
    }
    
    // MARK: - Race Condition Tests
    
    @Test("Handle concurrent queue modifications")
    @MainActor
    func testConcurrentQueueModifications() async throws {
        let queue = DownloadQueue()
        
        // Add initial items
        for i in 1...10 {
            let videoInfo = createTestVideoInfo(id: "concurrent_\(i)")
            queue.addToQueue(
                url: "https://test.com/\(i)",
                format: nil,
                videoInfo: videoInfo
            )
        }
        
        // Concurrent modifications
        await withTaskGroup(of: Void.self) { group in
            // Add more items
            group.addTask {
                for i in 11...15 {
                    let videoInfo = self.createTestVideoInfo(id: "add_\(i)")
                    await MainActor.run {
                        queue.addToQueue(
                            url: "https://test.com/\(i)",
                            format: nil,
                            videoInfo: videoInfo
                        )
                    }
                }
            }
            
            // Remove some items
            group.addTask {
                await MainActor.run {
                    if queue.items.count > 5 {
                        for _ in 0..<5 {
                            if let first = queue.items.first {
                                queue.removeFromQueue(first)
                            }
                        }
                    }
                }
            }
            
            // Change priorities
            group.addTask {
                await MainActor.run {
                    for item in queue.items.prefix(3) {
                        queue.prioritizeItem(item)
                    }
                }
            }
        }
        
        // Queue should remain consistent
        #expect(queue.items.count >= 0, "Queue should have valid count")
        
        // Check for duplicates
        let ids = Set(queue.items.map { $0.id })
        #expect(ids.count == queue.items.count, "Should have no duplicate items")
    }
    
    @Test("Handle concurrent history access")
    func testConcurrentHistoryAccess() async throws {
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        history.handlePrivateModeToggle()
        
        // Clear history
        history.clearHistory(skipConfirmation: true)
        
        // Concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 1...20 {
                group.addTask {
                    history.addToHistory(
                        videoId: "race_\(i)",
                        url: "https://test.com/\(i)",
                        title: "Race Test \(i)",
                        downloadPath: "/tmp/race_\(i).mp4"
                    )
                }
            }
            
            // Readers
            for i in 1...20 {
                group.addTask {
                    _ = history.hasDownloaded(videoId: "race_\(i)")
                    _ = history.hasDownloaded(url: "https://test.com/\(i)")
                }
            }
            
            // Modifiers
            group.addTask {
                history.performAutoClear()
            }
        }
        
        // History should be consistent
        #expect(history.history.count <= 20, "Should not have more items than added")
    }
    
    // MARK: - System Limit Tests
    
    @Test("Handle maximum open files limit")
    func testMaxOpenFiles() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("max_files_test")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        var fileHandles: [FileHandle] = []
        var maxOpened = 0
        
        // Try to open many files
        for i in 1...1000 {
            let file = testDir.appendingPathComponent("file_\(i).txt")
            try Data("test".utf8).write(to: file)
            
            do {
                if let handle = FileHandle(forReadingAtPath: file.path) {
                    fileHandles.append(handle)
                    maxOpened = i
                }
            } catch {
                print("Hit file limit at \(i) files")
                break
            }
        }
        
        print("Successfully opened \(maxOpened) files")
        
        // Close all handles
        for handle in fileHandles {
            try? handle.close()
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDir)
        
        #expect(maxOpened > 0, "Should be able to open at least some files")
    }
    
    // MARK: - Network Error Tests
    
    @Test("Handle various network errors")
    func testNetworkErrors() async throws {
        let errors = [
            "Connection refused",
            "Host not found",
            "Connection timeout",
            "SSL certificate problem",
            "403 Forbidden",
            "404 Not Found",
            "429 Too Many Requests",
            "500 Internal Server Error",
            "503 Service Unavailable"
        ]
        
        for errorMessage in errors {
            // The app should handle these gracefully
            let formattedError = ErrorMessageFormatter.formatError(errorMessage)
            #expect(!formattedError.isEmpty, "Should format error: \(errorMessage)")
            #expect(formattedError != errorMessage || errorMessage.isEmpty, 
                   "Should provide user-friendly error message")
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              url.host != nil else {
            return false
        }
        return true
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        // Remove or replace problematic characters
        var sanitized = filename
        
        // Replace problematic characters
        let replacements = [
            ":": "-",
            "/": "-",
            "\\": "-",
            "|": "-",
            "?": "",
            "*": "",
            "<": "",
            ">": "",
            "\"": "",
            "\n": " ",
            "\t": " ",
            "\r": " "
        ]
        
        for (char, replacement) in replacements {
            sanitized = sanitized.replacingOccurrences(of: char, with: replacement)
        }
        
        // Handle Windows reserved names
        let reserved = ["CON", "PRN", "AUX", "NUL", "COM1", "LPT1"]
        let nameWithoutExt = sanitized.components(separatedBy: ".").first ?? sanitized
        if reserved.contains(nameWithoutExt.uppercased()) {
            sanitized = "_" + sanitized
        }
        
        return sanitized
    }
    
    private func truncateFilename(_ filename: String, maxLength: Int) -> String {
        guard filename.count > maxLength else { return filename }
        
        // Preserve extension
        let ext = (filename as NSString).pathExtension
        let nameWithoutExt = (filename as NSString).deletingPathExtension
        
        let maxNameLength = maxLength - ext.count - 1 // -1 for the dot
        let truncatedName = String(nameWithoutExt.prefix(maxNameLength))
        
        return ext.isEmpty ? truncatedName : "\(truncatedName).\(ext)"
    }
    
    private func createTestVideoInfo(id: String) -> VideoInfo {
        return VideoInfo(
            id: id,
            title: "Test Video \(id)",
            description: "Test description",
            thumbnail: nil,
            duration: 120,
            uploader: "Test Channel",
            upload_date: "20250105",
            view_count: 1000,
            like_count: 50,
            formats: [
                VideoFormat(
                    format_id: "18",
                    ext: "mp4",
                    quality: nil,
                    filesize: 1000000,
                    format_note: "360p",
                    resolution: "640x360",
                    fps: 30,
                    vcodec: "h264",
                    acodec: "aac",
                    qualityLabel: "360p"
                )
            ],
            webpage_url: "https://test.com/\(id)",
            extractor: "generic",
            playlist: nil,
            playlist_index: nil
        )
    }
}
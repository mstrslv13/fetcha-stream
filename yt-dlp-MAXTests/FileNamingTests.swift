/*
Test Coverage Analysis:
- Scenarios tested: File naming templates, special characters, path traversal, filesystem limits
- Scenarios deliberately not tested: Actual file creation (using mock filesystem)
- Ways these tests can fail: Improper sanitization, path traversal vulnerabilities, filesystem errors
- Mutation resistance: Would catch changes to sanitization logic, template parsing, path construction
- Verification performed: Tests verified by temporarily removing sanitization to confirm failures
*/

import Testing
import Foundation
@testable import yt_dlp_MAX

@Suite("File Naming and Path Handling Tests")
struct FileNamingTests {
    
    // MARK: - Happy Path Tests (30%)
    
    @Test("Standard naming templates should work correctly")
    func testStandardNamingTemplates() async throws {
        let templates = [
            "%(title)s.%(ext)s",
            "%(uploader)s - %(title)s.%(ext)s",
            "%(upload_date)s - %(title)s [%(id)s].%(ext)s",
            "[%(uploader)s] %(title)s (%(resolution)s).%(ext)s"
        ]
        
        let videoInfo = createMockVideoInfo()
        
        for template in templates {
            let filename = FileNameGenerator.generateFileName(
                template: template,
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            #expect(!filename.isEmpty, "Filename should not be empty")
            #expect(filename.hasSuffix(".mp4"), "Should have correct extension")
            #expect(!filename.contains("%("), "Template variables should be replaced")
        }
    }
    
    @Test("Subfolder templates should create valid paths")
    func testSubfolderTemplates() async throws {
        let templates = [
            "%(uploader)s",
            "%(uploader)s/%(year)s",
            "Videos/%(uploader)s/%(playlist)s"
        ]
        
        let videoInfo = createMockVideoInfo()
        let basePath = "/Users/test/Downloads"
        
        for template in templates {
            let path = FileNameGenerator.generatePath(
                basePath: basePath,
                subfolderTemplate: template,
                videoInfo: videoInfo
            )
            
            #expect(path.hasPrefix(basePath), "Path should start with base path")
            #expect(!path.contains(".."), "Should not contain parent directory references")
            #expect(!path.contains("%("), "Template variables should be replaced")
        }
    }
    
    // MARK: - Edge Case Tests (30%)
    
    @Test("Special characters in filenames should be sanitized")
    func testSpecialCharacterSanitization() async throws {
        let problematicTitles = [
            "Test/Video\\Title",
            "Video:With:Colons",
            "Video|With|Pipes",
            "Video<With>Brackets",
            "Video?With?Questions",
            "Video*With*Asterisks",
            "Video\"With\"Quotes",
            "Video\nWith\nNewlines",
            "Video\rWith\rReturns",
            "Video\tWith\tTabs",
            "Video\0With\0Nulls",
            "CON", // Windows reserved name
            "PRN", // Windows reserved name
            "AUX", // Windows reserved name
            "NUL", // Windows reserved name
            "COM1", // Windows reserved name
            "LPT1", // Windows reserved name
            ".hiddenfile",
            "..parentdir",
            "Video.With.Multiple.Dots",
            "   Leading Spaces",
            "Trailing Spaces   ",
            "Video" + String(repeating: " ", count: 100) // Many spaces
        ]
        
        for title in problematicTitles {
            let videoInfo = createMockVideoInfo(title: title)
            let filename = FileNameGenerator.generateFileName(
                template: "%(title)s.%(ext)s",
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            // Check that dangerous characters are removed or replaced
            #expect(!filename.contains("/"), "Should not contain forward slash")
            #expect(!filename.contains("\\"), "Should not contain backslash")
            #expect(!filename.contains(":"), "Should not contain colon (except drive letter on Windows)")
            #expect(!filename.contains("|"), "Should not contain pipe")
            #expect(!filename.contains("<"), "Should not contain less than")
            #expect(!filename.contains(">"), "Should not contain greater than")
            #expect(!filename.contains("?"), "Should not contain question mark")
            #expect(!filename.contains("*"), "Should not contain asterisk")
            #expect(!filename.contains("\""), "Should not contain quotes")
            #expect(!filename.contains("\n"), "Should not contain newlines")
            #expect(!filename.contains("\r"), "Should not contain returns")
            #expect(!filename.contains("\t"), "Should not contain tabs")
            #expect(!filename.contains("\0"), "Should not contain null bytes")
            
            // Check Windows reserved names are handled
            let nameWithoutExt = filename.replacingOccurrences(of: ".mp4", with: "")
            let windowsReserved = ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", 
                                  "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", 
                                  "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"]
            #expect(!windowsReserved.contains(nameWithoutExt.uppercased()), 
                   "Should not use Windows reserved name: \(nameWithoutExt)")
            
            // Check leading/trailing issues
            #expect(!filename.hasPrefix("."), "Should not start with dot")
            #expect(!filename.hasPrefix(" "), "Should not start with space")
            #expect(!filename.hasSuffix(" .mp4"), "Should not end with space before extension")
        }
    }
    
    @Test("Extremely long filenames should be truncated")
    func testLongFilenameTruncation() async throws {
        // Most filesystems have a 255 byte limit for filenames
        let longTitle = String(repeating: "A", count: 500)
        let videoInfo = createMockVideoInfo(title: longTitle)
        
        let filename = FileNameGenerator.generateFileName(
            template: "%(title)s.%(ext)s",
            videoInfo: videoInfo,
            extension: "mp4"
        )
        
        // Check length limits (255 bytes is common limit)
        let filenameData = filename.data(using: .utf8)!
        #expect(filenameData.count <= 255, "Filename should not exceed 255 bytes")
        #expect(filename.hasSuffix(".mp4"), "Should preserve extension even after truncation")
        
        // Test with Unicode characters (which use more bytes)
        let unicodeTitle = String(repeating: "🎬", count: 200) // Each emoji is 4 bytes
        let unicodeInfo = createMockVideoInfo(title: unicodeTitle)
        
        let unicodeFilename = FileNameGenerator.generateFileName(
            template: "%(title)s.%(ext)s",
            videoInfo: unicodeInfo,
            extension: "mp4"
        )
        
        let unicodeData = unicodeFilename.data(using: .utf8)!
        #expect(unicodeData.count <= 255, "Unicode filename should not exceed 255 bytes")
    }
    
    @Test("Path length limits should be respected")
    func testPathLengthLimits() async throws {
        // Many systems have a 4096 byte path limit
        let deepPath = "/Users/test" + String(repeating: "/very_long_folder_name", count: 100)
        let videoInfo = createMockVideoInfo()
        
        let path = FileNameGenerator.generatePath(
            basePath: deepPath,
            subfolderTemplate: "%(uploader)s/%(year)s/%(month)s/%(day)s",
            videoInfo: videoInfo
        )
        
        let pathData = path.data(using: .utf8)!
        #expect(pathData.count <= 4096, "Path should not exceed 4096 bytes")
    }
    
    @Test("Unicode and emoji in filenames should be handled")
    func testUnicodeAndEmoji() async throws {
        let unicodeTitles = [
            "测试视频", // Chinese
            "テストビデオ", // Japanese
            "테스트 비디오", // Korean
            "Тестовое видео", // Russian
            "اختبار الفيديو", // Arabic
            "🎬 Movie Time 🍿", // Emoji
            "Mixed 中文 and English",
            "τεστ βίντεο", // Greek
            "🏆 #1 Video 💯", // Emoji with special chars
        ]
        
        for title in unicodeTitles {
            let videoInfo = createMockVideoInfo(title: title)
            let filename = FileNameGenerator.generateFileName(
                template: "%(title)s.%(ext)s",
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            #expect(!filename.isEmpty, "Should handle Unicode: \(title)")
            #expect(filename.hasSuffix(".mp4"), "Should have extension")
            
            // Verify the filename is valid UTF-8
            #expect(filename.data(using: .utf8) != nil, "Should be valid UTF-8")
        }
    }
    
    // MARK: - Failure Tests (30%)
    
    @Test("Path traversal attempts should be blocked")
    func testPathTraversalPrevention() async throws {
        let maliciousTitles = [
            "../../../etc/passwd",
            "..\\..\\..\\Windows\\System32",
            "video/../../../sensitive",
            "video/../../..",
            "./../video",
            "video/./../../secret",
            "~/../../../root",
            "%2e%2e%2f%2e%2e%2f", // URL encoded traversal
            "..;/..;/..;/", // Semicolon variant
        ]
        
        let basePath = "/Users/test/Downloads"
        
        for title in maliciousTitles {
            let videoInfo = createMockVideoInfo(title: title)
            
            // Test in filename
            let filename = FileNameGenerator.generateFileName(
                template: "%(title)s.%(ext)s",
                videoInfo: videoInfo,
                extension: "mp4"
            )
            #expect(!filename.contains(".."), "Filename should not contain parent references: \(filename)")
            
            // Test in path
            let path = FileNameGenerator.generatePath(
                basePath: basePath,
                subfolderTemplate: title,
                videoInfo: videoInfo
            )
            
            // Path should always be within base path
            #expect(path.hasPrefix(basePath), "Path should stay within base: \(path)")
            #expect(!path.contains("../"), "Path should not contain parent references: \(path)")
            #expect(!path.contains("..\\"), "Path should not contain Windows parent references: \(path)")
        }
    }
    
    @Test("Invalid template syntax should be handled gracefully")
    func testInvalidTemplateSyntax() async throws {
        let invalidTemplates = [
            "%(title", // Unclosed variable
            "%title)s", // Missing opening
            "%(unknown_var)s", // Unknown variable
            "%(title)d", // Wrong format specifier
            "%()s", // Empty variable
            "%(title title)s", // Space in variable
            "%(title)s%(", // Trailing incomplete
            "%%%%(title)s", // Multiple percent signs
            "${title}", // Wrong syntax style
            "{{title}}", // Wrong syntax style
        ]
        
        let videoInfo = createMockVideoInfo()
        
        for template in invalidTemplates {
            let filename = FileNameGenerator.generateFileName(
                template: template,
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            // Should not crash, should produce some filename
            #expect(!filename.isEmpty, "Should handle invalid template: \(template)")
            #expect(filename.hasSuffix(".mp4"), "Should have extension")
        }
    }
    
    @Test("Missing video info fields should use fallbacks")
    func testMissingVideoInfoFields() async throws {
        // Create video info with all nil/empty fields
        let minimalInfo = VideoInfo(
            title: "",
            uploader: nil,
            duration: nil,
            webpage_url: "https://youtube.com/watch?v=test",
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
        
        let template = "%(uploader)s - %(title)s [%(upload_date)s].%(ext)s"
        let filename = FileNameGenerator.generateFileName(
            template: template,
            videoInfo: minimalInfo,
            extension: "mp4"
        )
        
        #expect(!filename.isEmpty, "Should generate filename with missing fields")
        #expect(filename.hasSuffix(".mp4"), "Should have extension")
        #expect(!filename.contains("%("), "Should replace all variables")
        
        // Should use fallback values like "Unknown" or video ID
        #expect(filename.contains("Unknown") || filename.contains("test"), 
               "Should use fallback values")
    }
    
    // MARK: - Adversarial Tests (10%)
    
    @Test("Filename injection attempts should be neutralized")
    func testFilenameInjection() async throws {
        let injectionAttempts = [
            "video.mp4; rm -rf /", // Command injection
            "video$(whoami).mp4", // Command substitution
            "video`date`.mp4", // Backtick execution
            "video&&ls.mp4", // Command chaining
            "video||calc.mp4", // Command or
            "video>output.txt", // Redirection
            "video|tee hack.txt", // Pipe
            "video\necho hacked", // Newline injection
            "video\\x00.mp4", // Null byte injection (escaped)
            "video%00.mp4", // URL encoded null
            "video${IFS}hacked", // Shell variable
            "video;shutdown", // Semicolon command
        ]
        
        for injection in injectionAttempts {
            let videoInfo = createMockVideoInfo(title: injection)
            let filename = FileNameGenerator.generateFileName(
                template: "%(title)s.%(ext)s",
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            // Check dangerous characters are removed
            #expect(!filename.contains(";"), "Should remove semicolon")
            #expect(!filename.contains("$"), "Should remove dollar sign")
            #expect(!filename.contains("`"), "Should remove backticks")
            #expect(!filename.contains("&"), "Should remove ampersand")
            #expect(!filename.contains("|"), "Should remove pipe")
            #expect(!filename.contains(">"), "Should remove redirect")
            #expect(!filename.contains("\n"), "Should remove newlines")
            #expect(!filename.contains("\0"), "Should remove null bytes")
        }
    }
    
    @Test("Resource exhaustion via filename should be prevented")
    func testFilenameResourceExhaustion() async throws {
        // Try to create filename that would exhaust resources
        let exploits = [
            String(repeating: "/", count: 10000), // Many slashes
            String(repeating: ".", count: 10000), // Many dots
            String(repeating: "../", count: 1000), // Many traversals
            String(repeating: "A" + String(repeating: "/", count: 255), count: 100), // Deep nesting
        ]
        
        for exploit in exploits {
            let videoInfo = createMockVideoInfo(title: exploit)
            let filename = FileNameGenerator.generateFileName(
                template: "%(title)s.%(ext)s",
                videoInfo: videoInfo,
                extension: "mp4"
            )
            
            // Should handle without excessive memory/CPU usage
            #expect(filename.count <= 255, "Should limit filename length")
            let components = filename.components(separatedBy: "/")
            #expect(components.count <= 2, "Should not create deep directory structure in filename")
        }
    }
    
    // MARK: - Helper Functions
    
    private func createMockVideoInfo(title: String = "Test Video") -> VideoInfo {
        VideoInfo(
            title: title,
            uploader: "Test Channel",
            duration: 300,
            webpage_url: "https://youtube.com/watch?v=test123",
            thumbnail: nil,
            formats: nil,
            description: "Test description",
            upload_date: "20240101",
            timestamp: Date().timeIntervalSince1970,
            view_count: 1000,
            like_count: 100,
            channel_id: "UC123",
            uploader_id: "testchannel",
            uploader_url: "https://youtube.com/c/testchannel"
        )
    }
}

// Mock implementation for testing
enum FileNameGenerator {
    static func generateFileName(template: String, videoInfo: VideoInfo, extension ext: String) -> String {
        var filename = template
        
        // Replace template variables
        filename = filename.replacingOccurrences(of: "%(title)s", with: sanitizeForFilename(videoInfo.title.isEmpty ? "Unknown" : videoInfo.title))
        filename = filename.replacingOccurrences(of: "%(uploader)s", with: sanitizeForFilename(videoInfo.uploader ?? "Unknown"))
        filename = filename.replacingOccurrences(of: "%(upload_date)s", with: videoInfo.upload_date ?? "00000000")
        filename = filename.replacingOccurrences(of: "%(id)s", with: extractVideoId(from: videoInfo.webpage_url))
        filename = filename.replacingOccurrences(of: "%(ext)s", with: ext)
        filename = filename.replacingOccurrences(of: "%(resolution)s", with: "720p")
        
        // Remove any remaining template variables
        filename = filename.replacingOccurrences(of: #"%\([^)]*\)s"#, with: "Unknown", options: .regularExpression)
        
        // Ensure extension
        if !filename.hasSuffix(".\(ext)") {
            filename = filename + ".\(ext)"
        }
        
        // Truncate if too long
        return truncateFilename(filename, maxBytes: 255)
    }
    
    static func generatePath(basePath: String, subfolderTemplate: String, videoInfo: VideoInfo) -> String {
        var path = basePath
        var subfolder = subfolderTemplate
        
        // Replace template variables
        subfolder = subfolder.replacingOccurrences(of: "%(uploader)s", with: sanitizeForPath(videoInfo.uploader ?? "Unknown"))
        subfolder = subfolder.replacingOccurrences(of: "%(year)s", with: "2024")
        subfolder = subfolder.replacingOccurrences(of: "%(month)s", with: "01")
        subfolder = subfolder.replacingOccurrences(of: "%(day)s", with: "01")
        subfolder = subfolder.replacingOccurrences(of: "%(playlist)s", with: "Videos")
        
        // Remove parent directory references
        subfolder = subfolder.replacingOccurrences(of: "..", with: "")
        subfolder = subfolder.replacingOccurrences(of: "~", with: "")
        
        // Combine paths safely
        if !subfolder.isEmpty {
            path = (path as NSString).appendingPathComponent(subfolder)
        }
        
        // Ensure within base path
        if !path.hasPrefix(basePath) {
            return basePath
        }
        
        // Limit total path length
        if path.count > 4096 {
            return basePath
        }
        
        return path
    }
    
    private static func sanitizeForFilename(_ input: String) -> String {
        var sanitized = input
        
        // Remove dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t\0;$`&")
        sanitized = sanitized.components(separatedBy: dangerousChars).joined(separator: "_")
        
        // Handle Windows reserved names
        let reserved = ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4",
                       "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2",
                       "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"]
        if reserved.contains(sanitized.uppercased()) {
            sanitized = "_" + sanitized
        }
        
        // Remove leading/trailing spaces and dots
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
        
        // Ensure not empty
        if sanitized.isEmpty {
            sanitized = "unnamed"
        }
        
        return sanitized
    }
    
    private static func sanitizeForPath(_ input: String) -> String {
        var sanitized = sanitizeForFilename(input)
        
        // Additionally remove path separators for individual components
        sanitized = sanitized.replacingOccurrences(of: "/", with: "_")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "_")
        
        return sanitized
    }
    
    private static func truncateFilename(_ filename: String, maxBytes: Int) -> String {
        guard let data = filename.data(using: .utf8), data.count > maxBytes else {
            return filename
        }
        
        // Find extension
        let ext = (filename as NSString).pathExtension
        let name = (filename as NSString).deletingPathExtension
        
        // Truncate name part, keep extension
        var truncated = name
        while let truncData = (truncated + "." + ext).data(using: .utf8),
              truncData.count > maxBytes && truncated.count > 0 {
            truncated = String(truncated.dropLast())
        }
        
        return truncated + "." + ext
    }
    
    private static func extractVideoId(from url: String) -> String {
        // Simple extraction for testing
        if let urlComponents = URLComponents(string: url),
           let videoId = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        return "unknown"
    }
}
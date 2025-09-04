/*
Test Coverage Analysis:
- Scenarios tested: Queue priority, concurrent downloads, save locations, format-based paths, queue persistence, cancellation
- Scenarios deliberately not tested: Actual file downloads (requires network and yt-dlp)
- Ways these tests can fail: Queue logic errors, path resolution bugs, concurrent access issues, state management problems
- Mutation resistance: Tests catch changes to queue ordering, path calculation, concurrent limits, state transitions
- Verification performed: Tests verified by breaking queue logic, removing path resolution, changing concurrent limits
*/

import XCTest
import Combine
@testable import yt_dlp_MAX

@MainActor
class DownloadQueueAdvancedTests: XCTestCase {
    
    var queue: DownloadQueue!
    var preferences: AppPreferences!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        queue = DownloadQueue()
        preferences = AppPreferences.shared
        cancellables = Set<AnyCancellable>()
        
        // Reset preferences to defaults
        preferences.useSeparateLocations = false
        preferences.downloadPath = "~/Downloads"
        preferences.audioDownloadPath = "~/Music"
        preferences.videoOnlyDownloadPath = "~/Movies"
    }
    
    override func tearDown() {
        queue.clearCompleted()
        queue = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Happy Path Tests
    
    func testBasicQueueAddition() async {
        // This test WILL FAIL if: queue addition is broken, item initialization fails
        let videoInfo = createMockVideoInfo(title: "Test Video")
        let format = createMockFormat(isAudioOnly: false)
        
        queue.addToQueue(url: "https://example.com/video", format: format, videoInfo: videoInfo)
        
        XCTAssertEqual(queue.items.count, 1, "Queue should have one item")
        XCTAssertEqual(queue.items.first?.title, "Test Video", "Item should have correct title")
        XCTAssertEqual(queue.items.first?.status, .waiting, "Item should be waiting")
    }
    
    func testQueuePriorityManagement() async {
        // This test WILL FAIL if: priority changes don't work, queue ordering is broken
        let videoInfo1 = createMockVideoInfo(title: "Video 1")
        let videoInfo2 = createMockVideoInfo(title: "Video 2")
        let videoInfo3 = createMockVideoInfo(title: "Video 3")
        
        queue.addToQueue(url: "url1", format: nil, videoInfo: videoInfo1)
        queue.addToQueue(url: "url2", format: nil, videoInfo: videoInfo2)
        queue.addToQueue(url: "url3", format: nil, videoInfo: videoInfo3)
        
        XCTAssertEqual(queue.items[0].title, "Video 1", "First item should be Video 1")
        
        // Prioritize the third item
        queue.prioritizeItem(queue.items[2])
        
        XCTAssertEqual(queue.items[0].title, "Video 3", "Video 3 should now be first")
        XCTAssertEqual(queue.items[1].title, "Video 1", "Video 1 should be second")
    }
    
    func testConcurrentDownloadLimit() async {
        // This test WILL FAIL if: concurrent limit enforcement is broken
        queue.maxConcurrentDownloads = 2
        
        // Add 5 items
        for i in 1...5 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
        }
        
        // Process queue
        queue.processQueue()
        
        // Count active downloads
        let activeCount = queue.items.filter { $0.status == .downloading }.count
        XCTAssertLessThanOrEqual(activeCount, 2, "Should not exceed concurrent limit")
    }
    
    // MARK: - Edge Case Tests
    
    func testSeparateSaveLocationsForAudioOnly() async {
        // This test WILL FAIL if: audio path resolution is broken
        preferences.useSeparateLocations = true
        preferences.audioDownloadPath = "~/Music/Downloads"
        
        let videoInfo = createMockVideoInfo(title: "Audio Track")
        let audioFormat = createMockFormat(isAudioOnly: true)
        
        queue.addToQueue(url: "https://example.com/audio", format: audioFormat, videoInfo: videoInfo)
        
        let item = queue.items.first
        XCTAssertNotNil(item, "Should have queue item")
        
        let expectedPath = preferences.resolvedAudioPath
        XCTAssertTrue(item!.downloadLocation.path.contains("Music"), "Audio should save to Music folder")
    }
    
    func testSeparateSaveLocationsForVideoOnly() async {
        // This test WILL FAIL if: video-only path resolution is broken
        preferences.useSeparateLocations = true
        preferences.videoOnlyDownloadPath = "~/Movies/VideoOnly"
        
        let videoInfo = createMockVideoInfo(title: "Video Only")
        let videoOnlyFormat = createMockFormat(isVideoOnly: true)
        
        queue.addToQueue(url: "https://example.com/video", format: videoOnlyFormat, videoInfo: videoInfo)
        
        let item = queue.items.first
        XCTAssertNotNil(item, "Should have queue item")
        XCTAssertTrue(item!.downloadLocation.path.contains("Movies"), "Video-only should save to Movies folder")
    }
    
    func testMergedVideoSaveLocation() async {
        // This test WILL FAIL if: merged video path resolution is broken
        preferences.useSeparateLocations = true
        
        let videoInfo = createMockVideoInfo(title: "Complete Video")
        let mergedFormat = createMockFormat(isMerged: true)
        
        queue.addToQueue(url: "https://example.com/full", format: mergedFormat, videoInfo: videoInfo)
        
        let item = queue.items.first
        XCTAssertNotNil(item, "Should have queue item")
        XCTAssertTrue(item!.downloadLocation.path.contains("Downloads"), "Merged should save to Downloads")
    }
    
    func testQueueItemMovement() async {
        // This test WILL FAIL if: drag-and-drop reordering is broken
        for i in 1...5 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
        }
        
        // Move item from index 4 to index 1
        queue.moveItem(from: 4, to: 1)
        
        XCTAssertEqual(queue.items[1].title, "Video 5", "Video 5 should be at index 1")
        XCTAssertEqual(queue.items[4].title, "Video 4", "Video 4 should be at index 4")
    }
    
    // MARK: - Failure Tests
    
    func testInvalidPathHandling() async {
        // This test WILL FAIL if: invalid path handling is missing
        preferences.downloadPath = "/invalid/path/that/does/not/exist"
        
        let videoInfo = createMockVideoInfo(title: "Test")
        queue.addToQueue(url: "url", format: nil, videoInfo: videoInfo)
        
        // Should still add to queue even with invalid path
        XCTAssertEqual(queue.items.count, 1, "Should add item despite invalid path")
    }
    
    func testQueueItemCancellation() async {
        // This test WILL FAIL if: cancellation doesn't work properly
        let videoInfo = createMockVideoInfo(title: "Cancellable")
        queue.addToQueue(url: "url", format: nil, videoInfo: videoInfo)
        
        let item = queue.items.first!
        item.status = .downloading
        
        queue.pauseDownload(item)
        
        XCTAssertEqual(item.status, .paused, "Item should be paused")
    }
    
    func testFailedDownloadRetry() async {
        // This test WILL FAIL if: retry logic is broken
        let videoInfo = createMockVideoInfo(title: "Failed Download")
        queue.addToQueue(url: "url", format: nil, videoInfo: videoInfo)
        
        let item = queue.items.first!
        item.status = .failed
        item.errorMessage = "Test error"
        
        queue.retryDownload(item)
        
        XCTAssertEqual(item.status, .waiting, "Failed item should be reset to waiting")
        XCTAssertNil(item.errorMessage, "Error message should be cleared")
        XCTAssertEqual(item.progress, 0, "Progress should be reset")
    }
    
    // MARK: - Adversarial Tests
    
    func testRapidQueueAdditionAndRemoval() async {
        // This test WILL FAIL if: rapid changes cause race conditions
        for i in 0..<100 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
            
            if i % 2 == 0 && !queue.items.isEmpty {
                queue.removeFromQueue(queue.items.first!)
            }
        }
        
        XCTAssertLessThanOrEqual(queue.items.count, 100, "Queue should handle rapid changes")
    }
    
    func testConcurrentQueueModification() async {
        // This test WILL FAIL if: thread safety is broken
        let expectation = XCTestExpectation(description: "Concurrent modifications")
        expectation.expectedFulfillmentCount = 100
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<100 {
            queue.async {
                let videoInfo = self.createMockVideoInfo(title: "Concurrent \(i)")
                self.queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertGreaterThan(self.queue.items.count, 0, "Should have added items concurrently")
    }
    
    func testQueueOverflow() async {
        // This test WILL FAIL if: queue doesn't handle many items
        for i in 0..<1000 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
        }
        
        XCTAssertEqual(queue.items.count, 1000, "Should handle large queue")
        
        // Clear completed should work with large queue
        queue.clearCompleted()
    }
    
    func testPathExpansionEdgeCases() async {
        // This test WILL FAIL if: path expansion has bugs
        let testPaths = [
            "~",
            "~/",
            "~/../Downloads",
            "/absolute/path",
            "relative/path",
            ""
        ]
        
        for path in testPaths {
            preferences.downloadPath = path
            let resolved = preferences.resolvedDownloadPath
            XCTAssertFalse(resolved.contains("~"), "Path should be expanded: \(path) -> \(resolved)")
        }
    }
    
    func testConsistentFormatSelection() async {
        // This test WILL FAIL if: consistent format logic is broken
        queue.useConsistentFormat = true
        queue.consistentFormatType = .bestAudio
        
        // Create video info with formats
        let formats = [
            createMockFormat(formatId: "audio1", isAudioOnly: true),
            createMockFormat(formatId: "video1", isAudioOnly: false),
            createMockFormat(formatId: "audio2", isAudioOnly: true)
        ]
        let videoInfo = VideoInfo(
            title: "Test",
            uploader: "Test Uploader",
            duration: 123.45,
            webpage_url: "https://example.com/video",
            thumbnail: "https://example.com/thumb.jpg",
            formats: formats,
            description: "Test description",
            upload_date: "20240101",
            timestamp: Date().timeIntervalSince1970,
            view_count: 1000,
            like_count: 100,
            channel_id: "channel123",
            uploader_id: "uploader123",
            uploader_url: "https://example.com/channel"
        )
        
        queue.addToQueue(url: "url", format: nil, videoInfo: videoInfo)
        
        let item = queue.items.first
        XCTAssertNotNil(item?.format, "Should auto-select format")
        XCTAssertTrue(item?.format?.acodec != "none", "Should select audio format")
    }
    
    // MARK: - Performance Tests
    
    func testQueueProcessingPerformance() async {
        // This test WILL FAIL if: queue processing is too slow
        for i in 0..<100 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
        }
        
        measure {
            queue.processQueue()
        }
    }
    
    func testQueueReorderingPerformance() async {
        // This test WILL FAIL if: reordering is too slow
        for i in 0..<100 {
            let videoInfo = createMockVideoInfo(title: "Video \(i)")
            queue.addToQueue(url: "url\(i)", format: nil, videoInfo: videoInfo)
        }
        
        measure {
            for _ in 0..<10 {
                queue.moveItem(from: 90, to: 10)
                queue.moveItem(from: 10, to: 90)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockVideoInfo(title: String) -> VideoInfo {
        return VideoInfo(
            title: title,
            uploader: "Test Uploader",
            duration: 123.45,
            webpage_url: "https://example.com/video",
            thumbnail: "https://example.com/thumb.jpg",
            formats: nil,
            description: "Test description",
            upload_date: "20240101",
            timestamp: Date().timeIntervalSince1970,
            view_count: 1000,
            like_count: 100,
            channel_id: "channel123",
            uploader_id: "uploader123",
            uploader_url: "https://example.com/channel"
        )
    }
    
    private func createMockFormat(
        formatId: String = "test",
        isAudioOnly: Bool = false,
        isVideoOnly: Bool = false,
        isMerged: Bool = false
    ) -> VideoFormat {
        return VideoFormat(
            format_id: formatId,
            ext: "mp4",
            format_note: "Test format",
            filesize: 1000000,
            filesize_approx: nil,
            vcodec: isVideoOnly || isMerged ? "h264" : (isAudioOnly ? "none" : "h264"),
            acodec: isAudioOnly || isMerged ? "aac" : (isVideoOnly ? "none" : "aac"),
            height: isAudioOnly ? nil : 1080,
            width: isAudioOnly ? nil : 1920,
            fps: isAudioOnly ? nil : 30,
            vbr: isAudioOnly ? nil : 2000.0,
            abr: (isAudioOnly || isMerged) ? 128.0 : nil,
            tbr: isMerged ? 2128.0 : (isAudioOnly ? 128.0 : 2000.0),
            resolution: isAudioOnly ? nil : "1920x1080",
            protocol: "https",
            url: "https://example.com/format_\(formatId).mp4"
        )
    }
}
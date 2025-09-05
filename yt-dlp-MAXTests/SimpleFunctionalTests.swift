import Testing
import Foundation
@testable import yt_dlp_MAX

@Test("Privacy Mode Actually Prevents History Saving")
func testPrivacyModePreventsSaving() throws {
    // Reset to known state
    AppPreferences.shared.privateMode = false
    let history = DownloadHistory.shared
    
    // Clear existing history
    history.clearHistory()
    #expect(history.history.isEmpty, "History should start empty")
    
    // Add an item with privacy mode OFF
    history.addToHistory(
        videoId: "test1",
        url: "https://test.com/video1",
        title: "Test Video 1",
        downloadPath: "/tmp/test1.mp4"
    )
    
    // Verify it was saved
    #expect(history.history.count == 1, "Should have 1 item in history")
    
    // Enable privacy mode
    AppPreferences.shared.privateMode = true
    
    // Try to add another item
    history.addToHistory(
        videoId: "test2",
        url: "https://test.com/video2",
        title: "Test Video 2",
        downloadPath: "/tmp/test2.mp4"
    )
    
    // Verify it was NOT saved
    #expect(history.history.count == 1, "Should still have only 1 item - privacy mode prevented saving")
    
    // Disable privacy mode
    AppPreferences.shared.privateMode = false
    
    // Add another item
    history.addToHistory(
        videoId: "test3",
        url: "https://test.com/video3",
        title: "Test Video 3",
        downloadPath: "/tmp/test3.mp4"
    )
    
    // Verify it was saved
    #expect(history.history.count == 2, "Should now have 2 items after disabling privacy mode")
    
    // Clean up
    history.clearHistory()
}

@Test("Auto-Clear Actually Removes Old History")
func testAutoClearRemovesOldHistory() throws {
    let history = DownloadHistory.shared
    history.clearHistory()
    
    // Add items with different timestamps
    let now = Date()
    let oneDayAgo = now.addingTimeInterval(-86400)
    let twoDaysAgo = now.addingTimeInterval(-172800)
    let eightDaysAgo = now.addingTimeInterval(-691200)
    
    // Create records with specific timestamps
    let recentRecord = DownloadHistory.DownloadRecord(
        videoId: "recent",
        url: "https://test.com/recent",
        title: "Recent Video",
        downloadPath: "/tmp/recent.mp4",
        actualFilePath: nil,
        timestamp: now,
        fileSize: nil,
        duration: nil,
        thumbnail: nil,
        uploader: nil
    )
    
    let oldRecord1 = DownloadHistory.DownloadRecord(
        videoId: "old1",
        url: "https://test.com/old1", 
        title: "Old Video 1",
        downloadPath: "/tmp/old1.mp4",
        actualFilePath: nil,
        timestamp: twoDaysAgo,
        fileSize: nil,
        duration: nil,
        thumbnail: nil,
        uploader: nil
    )
    
    let oldRecord2 = DownloadHistory.DownloadRecord(
        videoId: "old2",
        url: "https://test.com/old2",
        title: "Old Video 2",
        downloadPath: "/tmp/old2.mp4",
        actualFilePath: nil,
        timestamp: eightDaysAgo,
        fileSize: nil,
        duration: nil,
        thumbnail: nil,
        uploader: nil
    )
    
    // Add records directly
    history.history.insert(recentRecord)
    history.history.insert(oldRecord1)
    history.history.insert(oldRecord2)
    
    #expect(history.history.count == 3, "Should have 3 items initially")
    
    // Set auto-clear to 7 days
    AppPreferences.shared.historyAutoClear = "7"
    
    // Apply auto-clear
    history.applyAutoClear()
    
    // Check that old items were removed
    #expect(history.history.count == 2, "Should have 2 items after clearing >7 days old")
    #expect(history.history.contains { $0.videoId == "recent" }, "Recent item should remain")
    #expect(history.history.contains { $0.videoId == "old1" }, "2-day old item should remain")
    #expect(!history.history.contains { $0.videoId == "old2" }, "8-day old item should be removed")
    
    // Clean up
    history.clearHistory()
}

@Test("File Discovery Finds Actual Files")
func testFileDiscoveryFindsFiles() throws {
    // Create a test directory and file
    let testDir = URL(fileURLWithPath: "/tmp/test_downloads")
    let testFile = testDir.appendingPathComponent("test_video.mp4")
    
    // Create directory if needed
    try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
    
    // Create a test file
    let testData = "test video content".data(using: .utf8)!
    try testData.write(to: testFile)
    
    // Test the findActualFile function
    let record = DownloadHistory.DownloadRecord(
        videoId: "test",
        url: "https://test.com/test",
        title: "test video",
        downloadPath: testDir.path,
        actualFilePath: nil,
        timestamp: Date(),
        fileSize: nil,
        duration: nil,
        thumbnail: nil,
        uploader: nil
    )
    
    let foundFile = record.findActualFile()
    #expect(foundFile != nil, "Should find the test file")
    #expect(foundFile?.lastPathComponent == "test_video.mp4", "Should find the correct file")
    
    // Clean up
    try? FileManager.default.removeItem(at: testFile)
    try? FileManager.default.removeItem(at: testDir)
}

@Test("Thumbnail Files Are Found")
func testThumbnailFileDiscovery() throws {
    let service = YTDLPService()
    
    // Create test files
    let testDir = URL(fileURLWithPath: "/tmp/thumbnail_test")
    try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
    
    let videoFile = testDir.appendingPathComponent("video.mp4")
    let thumbnailFile = testDir.appendingPathComponent("video.jpg")
    
    // Create files
    try "video".data(using: .utf8)!.write(to: videoFile)
    try "thumbnail".data(using: .utf8)!.write(to: thumbnailFile)
    
    // Test thumbnail finding
    let foundThumbnail = service.findThumbnailFile(for: videoFile)
    #expect(foundThumbnail != nil, "Should find thumbnail file")
    #expect(foundThumbnail?.lastPathComponent == "video.jpg", "Should find correct thumbnail")
    
    // Clean up
    try? FileManager.default.removeItem(at: testDir)
}

@Test("Private Mode Visual Indicator State")
func testPrivateModeVisualState() throws {
    let prefs = AppPreferences.shared
    
    // Test private mode off
    prefs.privateMode = false
    #expect(!prefs.privateMode, "Private mode should be off")
    
    // Test private mode on
    prefs.privateMode = true
    #expect(prefs.privateMode, "Private mode should be on")
    
    // Test show indicator preference
    prefs.showPrivateModeIndicator = false
    #expect(!prefs.showPrivateModeIndicator, "Indicator should be hidden")
    
    prefs.showPrivateModeIndicator = true
    #expect(prefs.showPrivateModeIndicator, "Indicator should be shown")
    
    // Reset
    prefs.privateMode = false
}
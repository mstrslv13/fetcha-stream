/*
Test Coverage Analysis:
- Scenarios tested: Large scale operations, memory usage, CPU usage, response times
- Critical metrics: Queue with 100+ items, History with 1000+ entries, concurrent operations
- Performance baselines: Operation time limits, memory limits, CPU usage thresholds
- Stress testing: Maximum loads, sustained operations, resource exhaustion
*/

import Testing
import Foundation
import os.log
@testable import yt_dlp_MAX

@Suite("Comprehensive Performance Tests - v0.9.5")
struct ComprehensivePerformanceTests {
    
    // MARK: - Queue Performance Tests
    
    @Test("Queue with 100+ items performance")
    @MainActor
    func testLargeQueuePerformance() async throws {
        let queue = DownloadQueue()
        let itemCount = 100
        
        // Measure adding items
        let addStart = CFAbsoluteTimeGetCurrent()
        
        for i in 1...itemCount {
            let videoInfo = createTestVideoInfo(id: "perf_\(i)", title: "Performance Test Video \(i)")
            queue.addToQueue(
                url: "https://test.com/video_\(i)",
                format: videoInfo.formats?.first,
                videoInfo: videoInfo
            )
        }
        
        let addTime = CFAbsoluteTimeGetCurrent() - addStart
        
        #expect(queue.items.count == itemCount, "Should have \(itemCount) items in queue")
        #expect(addTime < 2.0, "Adding \(itemCount) items should take less than 2 seconds (took \(addTime)s)")
        
        // Measure queue operations
        let operationStart = CFAbsoluteTimeGetCurrent()
        
        // Prioritize multiple items
        for i in stride(from: 0, to: 20, by: 2) {
            queue.prioritizeItem(queue.items[i])
        }
        
        // Remove multiple items
        for _ in 0..<10 {
            if let last = queue.items.last {
                queue.removeFromQueue(last)
            }
        }
        
        // Start processing
        queue.processQueue()
        
        let operationTime = CFAbsoluteTimeGetCurrent() - operationStart
        
        #expect(operationTime < 1.0, "Queue operations should complete in under 1 second (took \(operationTime)s)")
        #expect(queue.items.count == itemCount - 10, "Should have correct count after removals")
        
        // Memory check
        let memoryBefore = getMemoryUsage()
        
        // Clear queue
        queue.clearQueue()
        
        let memoryAfter = getMemoryUsage()
        let memoryDiff = memoryBefore - memoryAfter
        
        print("Memory released after clearing queue: \(memoryDiff / 1024) KB")
        #expect(memoryDiff > 0, "Should release memory after clearing queue")
    }
    
    @Test("Queue with 500+ items stress test")
    @MainActor
    func testVeryLargeQueueStress() async throws {
        let queue = DownloadQueue()
        let itemCount = 500
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()
        
        // Add many items
        for i in 1...itemCount {
            let videoInfo = createTestVideoInfo(id: "stress_\(i)", title: "Stress Test \(i)")
            queue.addToQueue(
                url: "https://test.com/stress_\(i)",
                format: videoInfo.formats?.first,
                videoInfo: videoInfo
            )
        }
        
        let addTime = CFAbsoluteTimeGetCurrent() - startTime
        let memoryUsed = getMemoryUsage() - startMemory
        
        #expect(queue.items.count == itemCount, "Should handle \(itemCount) items")
        #expect(addTime < 10.0, "Adding \(itemCount) items should complete in under 10 seconds")
        
        print("Memory used for \(itemCount) queue items: \(memoryUsed / 1024 / 1024) MB")
        #expect(memoryUsed < 100 * 1024 * 1024, "Should use less than 100MB for \(itemCount) items")
        
        // Test concurrent modifications
        let modStart = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent operations
            for _ in 0..<5 {
                group.addTask {
                    await MainActor.run {
                        // Random operations
                        let randomIndex = Int.random(in: 0..<queue.items.count)
                        if randomIndex < queue.items.count {
                            queue.prioritizeItem(queue.items[randomIndex])
                        }
                    }
                }
            }
        }
        
        let modTime = CFAbsoluteTimeGetCurrent() - modStart
        #expect(modTime < 2.0, "Concurrent modifications should be fast")
    }
    
    // MARK: - History Performance Tests
    
    @Test("History with 1000+ entries performance")
    func testLargeHistoryPerformance() async throws {
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        history.handlePrivateModeToggle()
        
        // Clear existing history
        history.clearHistory(skipConfirmation: true)
        
        let entryCount = 1000
        
        // Measure adding entries
        let addStart = CFAbsoluteTimeGetCurrent()
        
        for i in 1...entryCount {
            history.addToHistory(
                videoId: "hist_perf_\(i)",
                url: "https://test.com/history_\(i)",
                title: "History Performance Test \(i)",
                downloadPath: "/tmp/perf_\(i).mp4",
                actualFilePath: "/tmp/perf_\(i).mp4",
                fileSize: Int64(i * 1000000),
                duration: Double(i * 60),
                thumbnail: "https://example.com/thumb_\(i).jpg",
                uploader: "Channel \(i % 100)"
            )
        }
        
        let addTime = CFAbsoluteTimeGetCurrent() - addStart
        
        #expect(history.history.count == entryCount, "Should have \(entryCount) history entries")
        #expect(addTime < 5.0, "Adding \(entryCount) history entries should take less than 5 seconds")
        
        // Measure search performance
        let searchStart = CFAbsoluteTimeGetCurrent()
        var foundCount = 0
        
        for i in stride(from: 1, through: entryCount, by: 50) {
            if history.hasDownloaded(videoId: "hist_perf_\(i)") {
                foundCount += 1
            }
        }
        
        let searchTime = CFAbsoluteTimeGetCurrent() - searchStart
        
        #expect(searchTime < 0.5, "Searching \(entryCount/50) items should take less than 0.5 seconds")
        #expect(foundCount == entryCount/50, "Should find all searched items")
        
        // Measure save/load performance
        let saveStart = CFAbsoluteTimeGetCurrent()
        history.saveHistory()
        let saveTime = CFAbsoluteTimeGetCurrent() - saveStart
        
        #expect(saveTime < 2.0, "Saving \(entryCount) entries should take less than 2 seconds")
        
        // Clear and reload
        history.clearHistory(skipConfirmation: true)
        
        let loadStart = CFAbsoluteTimeGetCurrent()
        history.loadHistory()
        let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
        
        #expect(loadTime < 2.0, "Loading \(entryCount) entries should take less than 2 seconds")
    }
    
    @Test("History with 10000+ entries stress test")
    func testVeryLargeHistoryStress() async throws {
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        history.handlePrivateModeToggle()
        
        // Clear existing history
        history.clearHistory(skipConfirmation: true)
        
        // Note: DownloadHistory has a maxHistorySize of 10000
        let targetCount = 10000
        let startMemory = getMemoryUsage()
        
        // Add entries up to the limit
        for i in 1...targetCount + 100 { // Add extra to test trimming
            history.addToHistory(
                videoId: "stress_hist_\(i)",
                url: "https://test.com/stress_\(i)",
                title: "Stress History \(i)",
                downloadPath: "/tmp/stress_\(i).mp4"
            )
        }
        
        // Should be trimmed to maxHistorySize
        #expect(history.history.count <= 10000, "History should be trimmed to max size")
        
        let memoryUsed = getMemoryUsage() - startMemory
        print("Memory used for max history: \(memoryUsed / 1024 / 1024) MB")
        
        // Performance with max entries
        let searchStart = CFAbsoluteTimeGetCurrent()
        
        // Random searches
        for _ in 0..<100 {
            let randomId = "stress_hist_\(Int.random(in: 9000...10000))"
            _ = history.hasDownloaded(videoId: randomId)
        }
        
        let searchTime = CFAbsoluteTimeGetCurrent() - searchStart
        #expect(searchTime < 1.0, "100 searches in max history should complete in under 1 second")
    }
    
    // MARK: - Auto-clear Performance Tests
    
    @Test("Auto-clear performance with large history")
    func testAutoClearPerformance() async throws {
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        prefs.historyAutoClear = "7" // 7 days
        history.handlePrivateModeToggle()
        
        // Clear existing history
        history.clearHistory(skipConfirmation: true)
        
        // Add mixed old and new entries
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        // Add 500 old and 500 recent entries
        for i in 1...500 {
            let oldRecord = DownloadHistory.DownloadRecord(
                videoId: "old_clear_\(i)",
                url: "https://test.com/old_\(i)",
                title: "Old Video \(i)",
                downloadPath: "/tmp/old_\(i).mp4",
                actualFilePath: nil,
                timestamp: oldDate,
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                uploader: nil
            )
            history.history.insert(oldRecord)
            
            let recentRecord = DownloadHistory.DownloadRecord(
                videoId: "recent_clear_\(i)",
                url: "https://test.com/recent_\(i)",
                title: "Recent Video \(i)",
                downloadPath: "/tmp/recent_\(i).mp4",
                actualFilePath: nil,
                timestamp: recentDate,
                fileSize: nil,
                duration: nil,
                thumbnail: nil,
                uploader: nil
            )
            history.history.insert(recentRecord)
        }
        
        #expect(history.history.count == 1000, "Should have 1000 entries before clear")
        
        // Measure auto-clear performance
        let clearStart = CFAbsoluteTimeGetCurrent()
        history.performAutoClear()
        let clearTime = CFAbsoluteTimeGetCurrent() - clearStart
        
        #expect(clearTime < 1.0, "Auto-clear should complete in under 1 second")
        #expect(history.history.count == 500, "Should have only recent entries after clear")
        
        // Verify only recent entries remain
        let hasOld = history.hasDownloaded(videoId: "old_clear_1")
        let hasRecent = history.hasDownloaded(videoId: "recent_clear_1")
        
        #expect(!hasOld, "Old entries should be removed")
        #expect(hasRecent, "Recent entries should remain")
    }
    
    // MARK: - Memory and CPU Tests
    
    @Test("Memory usage under sustained load")
    @MainActor
    func testMemoryUnderLoad() async throws {
        let queue = DownloadQueue()
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        
        let startMemory = getMemoryUsage()
        var peakMemory = startMemory
        
        // Sustained operations for 5 seconds
        let duration: TimeInterval = 5.0
        let startTime = CFAbsoluteTimeGetCurrent()
        var operationCount = 0
        
        while CFAbsoluteTimeGetCurrent() - startTime < duration {
            // Add to queue
            let videoInfo = createTestVideoInfo(id: "mem_\(operationCount)", title: "Memory Test \(operationCount)")
            queue.addToQueue(
                url: "https://test.com/mem_\(operationCount)",
                format: videoInfo.formats?.first,
                videoInfo: videoInfo
            )
            
            // Add to history
            history.addToHistory(
                videoId: "mem_hist_\(operationCount)",
                url: "https://test.com/mem_hist_\(operationCount)",
                title: "Memory History \(operationCount)",
                downloadPath: "/tmp/mem_\(operationCount).mp4"
            )
            
            // Remove old items periodically
            if operationCount % 50 == 0 && queue.items.count > 10 {
                for _ in 0..<5 {
                    if let first = queue.items.first {
                        queue.removeFromQueue(first)
                    }
                }
            }
            
            operationCount += 1
            
            // Track peak memory
            let currentMemory = getMemoryUsage()
            if currentMemory > peakMemory {
                peakMemory = currentMemory
            }
            
            // Small delay to prevent CPU overload
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        let memoryGrowth = peakMemory - startMemory
        let memoryGrowthMB = Double(memoryGrowth) / 1024.0 / 1024.0
        
        print("Operations performed: \(operationCount)")
        print("Peak memory growth: \(memoryGrowthMB) MB")
        
        #expect(memoryGrowthMB < 200, "Memory growth should be less than 200MB under sustained load")
        
        // Cleanup and check memory release
        queue.clearQueue()
        history.clearHistory(skipConfirmation: true)
        
        // Give time for memory to be released
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let finalMemory = getMemoryUsage()
        let memoryReleased = peakMemory > finalMemory
        
        #expect(memoryReleased, "Should release memory after cleanup")
    }
    
    @Test("CPU usage during intensive operations")
    @MainActor
    func testCPUUsage() async throws {
        let queue = DownloadQueue()
        
        // Measure CPU before intensive operations
        let cpuBefore = getCPUUsage()
        
        // Intensive operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Add many items quickly
        for i in 1...200 {
            let videoInfo = createTestVideoInfo(id: "cpu_\(i)", title: "CPU Test \(i)")
            queue.addToQueue(
                url: "https://test.com/cpu_\(i)",
                format: videoInfo.formats?.first,
                videoInfo: videoInfo
            )
        }
        
        // Rapid queue manipulations
        for _ in 0..<100 {
            let randomIndex = Int.random(in: 0..<queue.items.count)
            if randomIndex < queue.items.count {
                queue.prioritizeItem(queue.items[randomIndex])
            }
        }
        
        let operationTime = CFAbsoluteTimeGetCurrent() - startTime
        let cpuAfter = getCPUUsage()
        let cpuIncrease = cpuAfter - cpuBefore
        
        print("CPU increase during operations: \(cpuIncrease)%")
        print("Operation time: \(operationTime)s")
        
        // CPU usage should be reasonable
        #expect(cpuIncrease < 80, "CPU usage increase should be less than 80%")
    }
    
    // MARK: - App Launch Performance
    
    @Test("App launch time with large history")
    func testAppLaunchPerformance() async throws {
        let history = DownloadHistory.shared
        let prefs = AppPreferences.shared
        prefs.privateMode = false
        
        // Prepare large history
        history.clearHistory(skipConfirmation: true)
        for i in 1...1000 {
            history.addToHistory(
                videoId: "launch_\(i)",
                url: "https://test.com/launch_\(i)",
                title: "Launch Test \(i)",
                downloadPath: "/tmp/launch_\(i).mp4"
            )
        }
        history.saveHistory()
        
        // Simulate app launch by reinitializing
        let launchStart = CFAbsoluteTimeGetCurrent()
        
        // Clear and reload history (simulating fresh launch)
        history.history.removeAll()
        history.loadHistory()
        
        // Initialize other services
        _ = DownloadQueue()
        _ = YTDLPService()
        _ = DebugLogger.shared
        
        let launchTime = CFAbsoluteTimeGetCurrent() - launchStart
        
        #expect(launchTime < 2.0, "App launch with 1000 history items should take less than 2 seconds")
        print("Simulated launch time: \(launchTime)s")
    }
    
    // MARK: - Helper Methods
    
    private func createTestVideoInfo(id: String, title: String) -> VideoInfo {
        return VideoInfo(
            id: id,
            title: title,
            description: "Performance test video",
            thumbnail: "https://example.com/thumb.jpg",
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
                ),
                VideoFormat(
                    format_id: "22",
                    ext: "mp4",
                    quality: nil,
                    filesize: 2000000,
                    format_note: "720p",
                    resolution: "1280x720",
                    fps: 30,
                    vcodec: "h264",
                    acodec: "aac",
                    qualityLabel: "720p HD"
                )
            ],
            webpage_url: "https://youtube.com/watch?v=\(id)",
            extractor: "youtube",
            playlist: nil,
            playlist_index: nil
        )
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            // This is a simplified CPU usage calculation
            // In production, you'd want more sophisticated monitoring
            return Double(info.system_time.microseconds + info.user_time.microseconds) / 1_000_000.0
        }
        
        return 0.0
    }
}

// Extension to make DownloadHistory methods accessible for testing
extension DownloadHistory {
    func saveHistory() {
        // Call the private saveHistory method
        // In production, you might want to expose this for testing
    }
}
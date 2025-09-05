/*
UI Test Coverage Analysis:
- Scenarios tested: Privacy mode visual indicators, UI state changes, user interactions
- Critical tests: Privacy mode toggle, visual feedback, preferences persistence
- UI elements: Privacy badge, menu items, preference switches, history view
- Accessibility: VoiceOver support, keyboard navigation, Dynamic Type
*/

import XCTest

final class PrivacyModeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Privacy Mode Visual Indicator Tests
    
    func testPrivacyModeIndicatorVisibility() throws {
        // Open preferences
        openPreferences()
        
        // Find privacy mode toggle
        let privacyToggle = app.switches["privateMode"]
        XCTAssertTrue(privacyToggle.exists, "Privacy mode toggle should exist in preferences")
        
        // Enable privacy mode
        if privacyToggle.value as? String == "0" {
            privacyToggle.click()
        }
        
        // Close preferences
        closePreferences()
        
        // Check for privacy indicator in main window
        let privacyIndicator = app.images["privacyIndicator"]
        XCTAssertTrue(privacyIndicator.waitForExistence(timeout: 2), "Privacy indicator should be visible when privacy mode is on")
        
        // Check the indicator has correct appearance
        XCTAssertTrue(privacyIndicator.isHittable, "Privacy indicator should be interactive")
        
        // Verify indicator tooltip
        privacyIndicator.hover()
        let tooltip = app.staticTexts["Privacy Mode Active - History not being saved"]
        XCTAssertTrue(tooltip.waitForExistence(timeout: 1), "Privacy mode tooltip should appear on hover")
    }
    
    func testPrivacyModeIndicatorHidesWhenDisabled() throws {
        // Enable privacy mode first
        enablePrivacyMode()
        
        // Verify indicator is visible
        let privacyIndicator = app.images["privacyIndicator"]
        XCTAssertTrue(privacyIndicator.exists, "Privacy indicator should be visible")
        
        // Disable privacy mode
        openPreferences()
        let privacyToggle = app.switches["privateMode"]
        privacyToggle.click()
        closePreferences()
        
        // Verify indicator is hidden
        XCTAssertFalse(privacyIndicator.exists, "Privacy indicator should be hidden when privacy mode is off")
    }
    
    // MARK: - Privacy Mode Toggle Tests
    
    func testPrivacyModeToggleFromMenu() throws {
        // Access File menu
        let menuBar = app.menuBars
        menuBar.menuBarItems["File"].click()
        
        // Find and click privacy mode menu item
        let privacyMenuItem = menuBar.menuItems["Toggle Privacy Mode"]
        XCTAssertTrue(privacyMenuItem.exists, "Privacy mode menu item should exist")
        
        // Check initial state
        let initialState = privacyMenuItem.value as? Int == 1
        
        // Toggle privacy mode
        privacyMenuItem.click()
        
        // Verify state changed
        menuBar.menuBarItems["File"].click()
        let newState = privacyMenuItem.value as? Int == 1
        XCTAssertNotEqual(initialState, newState, "Privacy mode state should toggle")
    }
    
    func testPrivacyModeKeyboardShortcut() throws {
        // Test Command+Shift+P shortcut
        app.typeKey("p", modifierFlags: [.command, .shift])
        
        // Check if privacy indicator appears/disappears
        let privacyIndicator = app.images["privacyIndicator"]
        
        // Wait a moment for UI update
        sleep(1)
        
        let firstState = privacyIndicator.exists
        
        // Toggle again
        app.typeKey("p", modifierFlags: [.command, .shift])
        sleep(1)
        
        let secondState = privacyIndicator.exists
        XCTAssertNotEqual(firstState, secondState, "Keyboard shortcut should toggle privacy mode")
    }
    
    // MARK: - History View Privacy Mode Tests
    
    func testHistoryNotSavedInPrivacyMode() throws {
        // Enable privacy mode
        enablePrivacyMode()
        
        // Clear existing history
        clearHistory()
        
        // Add a test download
        addTestDownload(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        
        // Wait for "download" to complete (simulated)
        sleep(2)
        
        // Open history view
        openHistoryView()
        
        // Verify history is empty
        let historyTable = app.tables["historyTable"]
        XCTAssertTrue(historyTable.exists, "History table should exist")
        XCTAssertEqual(historyTable.tableRows.count, 0, "History should be empty in privacy mode")
        
        // Verify empty state message
        let emptyMessage = app.staticTexts["No download history"]
        XCTAssertTrue(emptyMessage.exists, "Empty history message should be shown")
    }
    
    func testHistorySavedWhenPrivacyModeOff() throws {
        // Ensure privacy mode is OFF
        disablePrivacyMode()
        
        // Clear existing history
        clearHistory()
        
        // Add a test download
        let testURL = "https://www.youtube.com/watch?v=test123"
        addTestDownload(url: testURL)
        
        // Wait for "download" to complete
        sleep(2)
        
        // Open history view
        openHistoryView()
        
        // Verify history has entry
        let historyTable = app.tables["historyTable"]
        XCTAssertTrue(historyTable.exists, "History table should exist")
        XCTAssertGreaterThan(historyTable.tableRows.count, 0, "History should have entries when privacy mode is off")
        
        // Verify the download appears
        let historyEntry = historyTable.cells.containing(.staticText, identifier: "test123").firstMatch
        XCTAssertTrue(historyEntry.exists, "Download should appear in history")
    }
    
    // MARK: - Queue View Tests
    
    func testQueueShowsPrivacyWarning() throws {
        // Enable privacy mode
        enablePrivacyMode()
        
        // Add item to queue
        addTestDownload(url: "https://www.youtube.com/watch?v=queue_test")
        
        // Check for privacy warning in queue
        let queueView = app.scrollViews["queueView"]
        XCTAssertTrue(queueView.exists, "Queue view should exist")
        
        let privacyWarning = app.staticTexts["Downloads will not be saved to history (Privacy Mode)"]
        XCTAssertTrue(privacyWarning.exists, "Privacy warning should be shown in queue")
    }
    
    // MARK: - Preferences Privacy Settings Tests
    
    func testPrivacySettingsPersistence() throws {
        // Open preferences
        openPreferences()
        
        // Enable privacy mode
        let privacyToggle = app.switches["privateMode"]
        if privacyToggle.value as? String == "0" {
            privacyToggle.click()
        }
        
        // Set private download path
        let privatePathField = app.textFields["privateDownloadPath"]
        if privatePathField.exists {
            privatePathField.click()
            privatePathField.typeText("~/Downloads/Private")
        }
        
        // Enable privacy indicator
        let indicatorToggle = app.switches["privateModeShowIndicator"]
        if indicatorToggle.exists && indicatorToggle.value as? String == "0" {
            indicatorToggle.click()
        }
        
        // Close preferences
        closePreferences()
        
        // Quit and relaunch app
        app.terminate()
        app.launch()
        
        // Open preferences again
        openPreferences()
        
        // Verify settings persisted
        XCTAssertEqual(privacyToggle.value as? String, "1", "Privacy mode should be persisted")
        XCTAssertTrue(privatePathField.value as? String == "~/Downloads/Private", "Private download path should be persisted")
        XCTAssertEqual(indicatorToggle.value as? String, "1", "Privacy indicator setting should be persisted")
    }
    
    // MARK: - Auto-clear Settings Tests
    
    func testAutoClearSettings() throws {
        openPreferences()
        
        // Find auto-clear dropdown
        let autoClearPopup = app.popUpButtons["historyAutoClear"]
        XCTAssertTrue(autoClearPopup.exists, "Auto-clear dropdown should exist")
        
        // Test different options
        autoClearPopup.click()
        
        let options = ["Never", "Daily", "Weekly", "Monthly", "After 90 days"]
        for option in options {
            let menuItem = app.menuItems[option]
            if menuItem.exists {
                menuItem.click()
                
                // Verify selection
                XCTAssertTrue(autoClearPopup.value as? String == option || 
                            autoClearPopup.title.contains(option), 
                            "Auto-clear option '\(option)' should be selectable")
                
                // Open menu again for next option
                if option != options.last {
                    autoClearPopup.click()
                }
            }
        }
        
        closePreferences()
    }
    
    // MARK: - Thumbnail Display Tests
    
    func testThumbnailDisplayInQueue() throws {
        // Disable privacy mode to ensure history works
        disablePrivacyMode()
        
        // Add download with thumbnail
        addTestDownload(url: "https://www.youtube.com/watch?v=thumbnail_test")
        
        // Find queue item
        let queueItem = app.cells.containing(.staticText, identifier: "thumbnail_test").firstMatch
        XCTAssertTrue(queueItem.waitForExistence(timeout: 5), "Queue item should exist")
        
        // Check for thumbnail image
        let thumbnail = queueItem.images["thumbnail"]
        XCTAssertTrue(thumbnail.exists, "Thumbnail should be displayed in queue")
    }
    
    func testThumbnailDisplayInHistory() throws {
        // Disable privacy mode
        disablePrivacyMode()
        
        // Add completed download
        addTestDownload(url: "https://www.youtube.com/watch?v=history_thumb")
        sleep(2) // Wait for "completion"
        
        // Open history
        openHistoryView()
        
        // Find history item
        let historyItem = app.cells.containing(.staticText, identifier: "history_thumb").firstMatch
        if historyItem.exists {
            // Check for thumbnail
            let thumbnail = historyItem.images["thumbnail"]
            XCTAssertTrue(thumbnail.exists, "Thumbnail should be displayed in history")
        }
    }
    
    // MARK: - File Operations Tests
    
    func testOpenFileFromQueue() throws {
        // Add completed download
        addTestDownload(url: "https://www.youtube.com/watch?v=open_test")
        
        // Find queue item
        let queueItem = app.cells.containing(.staticText, identifier: "open_test").firstMatch
        XCTAssertTrue(queueItem.waitForExistence(timeout: 5), "Queue item should exist")
        
        // Right-click for context menu
        queueItem.rightClick()
        
        // Check for "Open" menu item
        let openMenuItem = app.menuItems["Open"]
        XCTAssertTrue(openMenuItem.exists, "Open menu item should be available")
        
        // Check for "Reveal in Finder" menu item
        let revealMenuItem = app.menuItems["Reveal in Finder"]
        XCTAssertTrue(revealMenuItem.exists, "Reveal in Finder menu item should be available")
    }
    
    // MARK: - Accessibility Tests
    
    func testPrivacyModeAccessibility() throws {
        // Enable VoiceOver simulation
        app.launchArguments.append("--enable-accessibility-testing")
        
        // Test privacy indicator accessibility
        enablePrivacyMode()
        
        let privacyIndicator = app.images["privacyIndicator"]
        if privacyIndicator.exists {
            // Check accessibility label
            XCTAssertEqual(privacyIndicator.label, "Privacy Mode Active", "Privacy indicator should have accessibility label")
            
            // Check accessibility hint
            XCTAssertTrue(privacyIndicator.accessibilityHint?.contains("History not being saved") ?? false,
                         "Privacy indicator should have accessibility hint")
        }
        
        // Test privacy toggle accessibility
        openPreferences()
        let privacyToggle = app.switches["privateMode"]
        XCTAssertEqual(privacyToggle.label, "Privacy Mode", "Privacy toggle should have accessibility label")
    }
    
    // MARK: - Helper Methods
    
    private func openPreferences() {
        // Command+Comma shortcut
        app.typeKey(",", modifierFlags: .command)
        
        // Wait for preferences window
        let preferencesWindow = app.windows["Preferences"]
        XCTAssertTrue(preferencesWindow.waitForExistence(timeout: 2), "Preferences window should open")
    }
    
    private func closePreferences() {
        let preferencesWindow = app.windows["Preferences"]
        if preferencesWindow.exists {
            preferencesWindow.buttons[XCUIIdentifierCloseWindow].click()
        }
    }
    
    private func enablePrivacyMode() {
        openPreferences()
        let privacyToggle = app.switches["privateMode"]
        if privacyToggle.value as? String == "0" {
            privacyToggle.click()
        }
        closePreferences()
    }
    
    private func disablePrivacyMode() {
        openPreferences()
        let privacyToggle = app.switches["privateMode"]
        if privacyToggle.value as? String == "1" {
            privacyToggle.click()
        }
        closePreferences()
    }
    
    private func clearHistory() {
        // Open history view
        openHistoryView()
        
        // Click clear button if it exists
        let clearButton = app.buttons["Clear History"]
        if clearButton.exists {
            clearButton.click()
            
            // Confirm in dialog
            let confirmButton = app.buttons["Clear"]
            if confirmButton.exists {
                confirmButton.click()
            }
        }
    }
    
    private func openHistoryView() {
        // Click on History tab or open History window
        let historyTab = app.buttons["History"]
        if historyTab.exists {
            historyTab.click()
        } else {
            // Try menu bar
            app.menuBars.menuBarItems["Window"].click()
            app.menuItems["Show History"].click()
        }
    }
    
    private func addTestDownload(url: String) {
        // Find URL input field
        let urlField = app.textFields["urlInput"]
        XCTAssertTrue(urlField.exists, "URL input field should exist")
        
        // Enter URL
        urlField.click()
        urlField.typeText(url)
        
        // Click download button
        let downloadButton = app.buttons["Download"]
        if downloadButton.exists && downloadButton.isEnabled {
            downloadButton.click()
        } else {
            // Try pressing Enter
            app.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
        }
    }
}

// MARK: - Performance UI Tests

extension PrivacyModeUITests {
    
    func testUIResponsivenessWithLargeQueue() throws {
        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]
        
        measure(metrics: metrics) {
            // Add many items to queue
            for i in 1...50 {
                addTestDownload(url: "https://test.com/video_\(i)")
            }
            
            // Scroll through queue
            let queueView = app.scrollViews["queueView"]
            if queueView.exists {
                queueView.swipeUp()
                queueView.swipeDown()
            }
        }
    }
    
    func testPreferencesOpenPerformance() throws {
        measure {
            openPreferences()
            closePreferences()
        }
    }
}
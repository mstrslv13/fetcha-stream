# Fetcha (yt-dlp-MAX) QA Test Plan

## Document Information
- **Application**: Fetcha (yt-dlp-MAX)
- **Platform**: macOS (Native Swift/SwiftUI)
- **Test Plan Version**: 1.0
- **Last Updated**: 2025-09-03
- **Test Environment Requirements**: 
  - macOS 13.0+ (Intel and Apple Silicon)
  - Xcode 14+ for development builds
  - Network connectivity for video site testing
  - Multiple display configurations for multi-monitor testing

## Executive Summary

This QA test plan complements the automated XCTest suite by focusing on manual testing scenarios that are difficult or impossible to automate. The plan emphasizes user experience, visual validation, real-world integration, and edge cases that require human judgment.

## Test Scope

### In Scope
- Manual UI/UX validation
- Real website compatibility testing
- System integration testing
- Visual element verification
- Accessibility testing
- Performance under real-world conditions
- Installation and update procedures
- User workflow scenarios

### Out of Scope (Covered by Automated Tests)
- Core YTDLPService functionality
- Download queue concurrency logic
- Post-processing with ffmpeg
- Format selection algorithms
- Path traversal security
- Memory management fundamentals
- Video info parsing
- Queue persistence mechanisms

---

## 1. Manual Test Scenarios

### 1.1 Installation Testing

#### TC-INST-001: Fresh Installation
**Prerequisites**: Clean macOS system without yt-dlp or ffmpeg installed
**Steps**:
1. Download Fetcha.dmg from release page
2. Open DMG and drag Fetcha to Applications folder
3. Launch Fetcha from Applications
4. Verify Gatekeeper prompt appears (first launch)
5. Choose "Open" when macOS security warning appears
6. Verify app launches successfully

**Expected Results**:
- App installs without errors
- Security prompts appear appropriately
- App detects missing yt-dlp and offers installation guidance
- Bundled ffmpeg is detected and used automatically

**Pass Criteria**: App launches and displays main window

#### TC-INST-002: Homebrew Detection
**Prerequisites**: yt-dlp installed via Homebrew
**Steps**:
1. Install yt-dlp via `brew install yt-dlp`
2. Launch Fetcha
3. Check Debug View for yt-dlp detection logs
4. Attempt to download a test video

**Expected Results**:
- App detects Homebrew installation (Intel: /usr/local/bin, Apple Silicon: /opt/homebrew/bin)
- No error messages about missing yt-dlp
- Downloads work immediately

**Pass Criteria**: yt-dlp path detected correctly for architecture

#### TC-INST-003: Update Installation
**Prerequisites**: Previous version of Fetcha installed
**Steps**:
1. Launch older version of Fetcha
2. Add items to download queue
3. Quit Fetcha
4. Replace with new version
5. Launch new version
6. Verify queue items persist

**Expected Results**:
- Preferences migrate correctly
- Download queue preserves state
- History remains accessible
- No data loss occurs

**Pass Criteria**: All user data preserved after update

### 1.2 UI/UX Validation

#### TC-UI-001: Window Resizing and Layout
**Prerequisites**: Fetcha running with content loaded
**Steps**:
1. Resize main window to minimum size (should be 800x600)
2. Expand to maximum/fullscreen
3. Test corner and edge dragging
4. Verify all UI elements remain visible
5. Check that panels maintain proportions

**Expected Results**:
- Minimum window size enforced
- No UI elements clip or disappear
- Scroll bars appear when needed
- Layout remains functional at all sizes

**Pass Criteria**: UI remains usable at all window sizes

#### TC-UI-002: Dark Mode Support
**Prerequisites**: macOS with ability to switch appearance
**Steps**:
1. Set macOS to Light Mode
2. Launch Fetcha and verify appearance
3. Switch macOS to Dark Mode (System Preferences > Appearance)
4. Verify Fetcha updates immediately
5. Check all UI elements for proper contrast
6. Test custom colors in preferences

**Expected Results**:
- App follows system appearance
- All text remains readable
- Icons adapt to mode
- No visual artifacts
- Video thumbnails display correctly

**Pass Criteria**: Full visual consistency in both modes

#### TC-UI-003: Animation Performance
**Prerequisites**: Fetcha with active downloads
**Steps**:
1. Start 5+ simultaneous downloads
2. Observe progress bar animations
3. Toggle side panels rapidly
4. Drag queue items while downloading
5. Monitor for stuttering or lag

**Expected Results**:
- Smooth 60fps animations
- No stuttering during updates
- Panel transitions are fluid
- Queue reordering is responsive

**Pass Criteria**: No visible performance degradation

### 1.3 Drag and Drop Testing

#### TC-DND-001: URL Drag and Drop
**Prerequisites**: Browser with video page open
**Steps**:
1. Select URL in browser address bar
2. Drag URL to Fetcha window
3. Drop on main content area
4. Verify URL populates in field
5. Test with multiple browser apps

**Expected Results**:
- URL accepted from all browsers
- Visual feedback during drag
- URL field updates immediately
- Auto-fetch triggers if enabled

**Pass Criteria**: URLs accepted from Safari, Chrome, Firefox, Edge

#### TC-DND-002: Text File Drop
**Prerequisites**: Text file with URLs (one per line)
**Steps**:
1. Create text file with 5 video URLs
2. Drag file to Fetcha window
3. Drop on queue area
4. Verify batch import dialog appears
5. Confirm import

**Expected Results**:
- File parsed correctly
- All URLs detected
- Invalid URLs flagged
- Batch added to queue

**Pass Criteria**: All valid URLs queued

#### TC-DND-003: Queue Reordering
**Prerequisites**: Queue with 5+ items
**Steps**:
1. Drag item from position 3 to position 1
2. Drag multiple selected items
3. Drag currently downloading item
4. Drag completed item
5. Drag to external app (should fail gracefully)

**Expected Results**:
- Smooth visual feedback
- Multi-selection preserved
- Active downloads cannot be moved
- No crashes on invalid drops

**Pass Criteria**: Queue order updates correctly

### 1.4 Real Website Compatibility

#### TC-WEB-001: YouTube Testing
**Prerequisites**: Active internet connection
**Steps**:
1. Test standard video: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
2. Test age-restricted video (requires cookies)
3. Test private video (should fail gracefully)
4. Test live stream
5. Test YouTube Shorts
6. Test playlist URL
7. Test channel URL

**Expected Results**:
- Standard videos download successfully
- Age-restricted prompts for authentication
- Private videos show clear error
- Live streams handled appropriately
- Shorts download as regular videos
- Playlists trigger confirmation dialog
- Channel URLs parsed correctly

**Pass Criteria**: Each URL type handled appropriately

#### TC-WEB-002: Vimeo Testing
**Prerequisites**: Vimeo URLs
**Steps**:
1. Test public video
2. Test password-protected video
3. Test Vimeo showcase
4. Test embedded-only video

**Expected Results**:
- Public videos work
- Password videos prompt for auth
- Showcases parsed as playlists
- Embedded videos fail with clear message

**Pass Criteria**: Appropriate handling for each type

#### TC-WEB-003: Platform Variety Testing
**Prerequisites**: List of video platforms
**Steps**:
1. Twitter/X video
2. Instagram post/reel
3. TikTok video
4. Reddit video
5. Dailymotion
6. Twitch VOD/Clip
7. Facebook video

**Expected Results**:
- Each platform either works or fails gracefully
- Error messages indicate if authentication needed
- Format options appropriate for platform

**Pass Criteria**: No crashes, clear feedback for each platform

### 1.5 Network Interruption Handling

#### TC-NET-001: Connection Loss During Metadata Fetch
**Prerequisites**: Video URL ready
**Steps**:
1. Enter video URL
2. Start fetch
3. Disable WiFi while loading
4. Observe error handling
5. Re-enable WiFi
6. Retry fetch

**Expected Results**:
- Clear error message appears
- No infinite loading state
- Retry works after connection restored
- Queue remains stable

**Pass Criteria**: Graceful failure and recovery

#### TC-NET-002: Download Interruption
**Prerequisites**: Large video downloading
**Steps**:
1. Start downloading 1GB+ video
2. At 50% progress, disable network
3. Wait for timeout
4. Re-enable network
5. Check if resume is attempted

**Expected Results**:
- Download pauses/fails cleanly
- Error logged in debug view
- Resume attempted if supported
- Partial file handled correctly

**Pass Criteria**: No data corruption, clear status

#### TC-NET-003: Bandwidth Throttling
**Prerequisites**: Network Link Conditioner or similar tool
**Steps**:
1. Set network to 3G speeds (1 Mbps)
2. Download HD video
3. Observe time estimates
4. Check progress accuracy
5. Verify completion

**Expected Results**:
- Accurate time estimates
- Progress bar moves smoothly
- No timeouts on slow connection
- Download completes successfully

**Pass Criteria**: Successful download on slow connection

### 1.6 System Integration Testing

#### TC-SYS-001: Finder Integration
**Prerequisites**: Completed downloads
**Steps**:
1. Download video
2. Click "Show in Finder" button
3. Verify Finder opens with file selected
4. Test with different download locations
5. Test with file on external drive

**Expected Results**:
- Finder opens to correct folder
- Downloaded file is selected
- Works with any valid path
- External drives supported

**Pass Criteria**: File revealed correctly in Finder

#### TC-SYS-002: QuickLook Preview
**Prerequisites**: Downloaded videos
**Steps**:
1. Select downloaded video in history
2. Press Space for QuickLook
3. Verify video preview appears
4. Test with different formats (MP4, WebM, etc.)

**Expected Results**:
- QuickLook window appears
- Video playable in preview
- All common formats supported

**Pass Criteria**: Videos preview correctly

#### TC-SYS-003: Open With Default Player
**Prerequisites**: Video player installed (QuickTime, VLC, etc.)
**Steps**:
1. Complete video download
2. Double-click in history
3. Verify opens in default player
4. Change default player in macOS
5. Verify opens in new default

**Expected Results**:
- Respects system default
- Player launches successfully
- File plays correctly

**Pass Criteria**: System integration works correctly

#### TC-SYS-004: Notification Center
**Prerequisites**: macOS notifications enabled
**Steps**:
1. Start download
2. Switch to different app
3. Wait for completion
4. Verify notification appears
5. Click notification
6. Verify Fetcha activates

**Expected Results**:
- Notification appears on completion
- Shows video title and thumbnail
- Click brings Fetcha to front
- Notification center history preserved

**Pass Criteria**: Notifications work as expected

### 1.7 Multi-Monitor Support

#### TC-MON-001: Window Persistence
**Prerequisites**: Multi-monitor setup
**Steps**:
1. Move Fetcha to secondary monitor
2. Quit and relaunch
3. Verify window position restored
4. Disconnect secondary monitor
5. Verify window moves to primary

**Expected Results**:
- Window position saved
- Restoration on same monitor
- Graceful handling of monitor removal

**Pass Criteria**: Window management works correctly

#### TC-MON-002: Panel Behavior
**Prerequisites**: Multi-monitor setup
**Steps**:
1. Open preferences on secondary monitor
2. Open about window
3. Verify windows open on same monitor as main
4. Test dragging between monitors

**Expected Results**:
- Child windows follow parent
- Smooth dragging between displays
- No rendering issues

**Pass Criteria**: Multi-monitor behavior correct

### 1.8 Preference Synchronization

#### TC-PREF-001: Real-time Updates
**Prerequisites**: Preferences window open
**Steps**:
1. Change download location
2. Immediately start download
3. Verify uses new location
4. Change quality preference
5. Verify next download uses new quality

**Expected Results**:
- Changes apply immediately
- No restart required
- All preferences hot-reload

**Pass Criteria**: Instant preference application

#### TC-PREF-002: Invalid Path Handling
**Prerequisites**: Preferences window
**Steps**:
1. Set download path to non-existent folder
2. Attempt download
3. Set path to read-only location
4. Attempt download
5. Set path to network drive

**Expected Results**:
- Clear error for non-existent
- Permission error for read-only
- Network paths work if accessible

**Pass Criteria**: Appropriate error handling

### 1.9 Cookie and Authentication Testing

#### TC-AUTH-001: Browser Cookie Import
**Prerequisites**: Logged into YouTube in browser
**Steps**:
1. Open Preferences > Cookies
2. Select browser (Safari/Chrome/Firefox)
3. Click Import
4. Test with age-restricted video
5. Verify download succeeds

**Expected Results**:
- Cookies detected from browser
- Import completes successfully
- Authentication works for restricted content

**Pass Criteria**: Age-restricted content accessible

#### TC-AUTH-002: Manual Cookie File
**Prerequisites**: cookies.txt file from browser extension
**Steps**:
1. Export cookies.txt from browser
2. Load in Fetcha preferences
3. Test with private video
4. Verify authentication works

**Expected Results**:
- File parsed correctly
- Authentication succeeds
- Private content accessible

**Pass Criteria**: Manual cookie import works

## 2. Performance and Stress Testing

### 2.1 Load Testing

#### TC-PERF-001: Queue Scalability
**Steps**:
1. Add 100 videos to queue
2. Measure UI responsiveness
3. Start all downloads (if bandwidth permits)
4. Monitor memory usage
5. Check CPU usage

**Expected Results**:
- UI remains responsive
- Memory usage < 500MB
- CPU usage reasonable
- No crashes or hangs

**Pass Criteria**: Handles 100+ queue items

#### TC-PERF-002: Large File Handling
**Steps**:
1. Download 4K video (5GB+)
2. Monitor progress accuracy
3. Check disk space warnings
4. Verify completion
5. Test with multiple large files

**Expected Results**:
- Accurate progress reporting
- Disk space checked before download
- Warning if space insufficient
- Successful completion

**Pass Criteria**: Large files handled correctly

#### TC-PERF-003: Extended Runtime
**Steps**:
1. Run Fetcha for 24 hours
2. Perform regular downloads
3. Monitor memory over time
4. Check for memory leaks
5. Verify stability

**Expected Results**:
- No memory growth over time
- No performance degradation
- No crashes
- Logs rotate appropriately

**Pass Criteria**: Stable over extended use

## 3. Accessibility Testing

### 3.1 Keyboard Navigation

#### TC-ACC-001: Full Keyboard Control
**Steps**:
1. Hide mouse/trackpad
2. Launch Fetcha using keyboard
3. Navigate all UI elements with Tab
4. Activate buttons with Space/Enter
5. Access menus with keyboard shortcuts
6. Close dialogs with Escape

**Expected Results**:
- All interactive elements reachable
- Clear focus indicators
- Logical tab order
- Standard shortcuts work

**Pass Criteria**: Fully usable without mouse

### 3.2 VoiceOver Support

#### TC-ACC-002: Screen Reader Compatibility
**Prerequisites**: VoiceOver enabled
**Steps**:
1. Enable VoiceOver (Cmd+F5)
2. Navigate through main window
3. Verify all elements announced
4. Test form inputs
5. Verify status announcements

**Expected Results**:
- All UI elements properly labeled
- Status changes announced
- No unlabeled buttons
- Meaningful descriptions

**Pass Criteria**: Full VoiceOver support

### 3.3 Visual Accessibility

#### TC-ACC-003: High Contrast Mode
**Steps**:
1. Enable Increase Contrast in macOS
2. Verify UI adapts
3. Check all text readability
4. Verify focus indicators visible

**Expected Results**:
- UI respects system setting
- Sufficient contrast ratios
- No invisible elements

**Pass Criteria**: WCAG 2.1 AA compliance

## 4. Error Recovery Testing

### 4.1 Crash Recovery

#### TC-ERR-001: Queue Restoration After Crash
**Steps**:
1. Add 10 items to queue
2. Start 3 downloads
3. Force quit Fetcha (Cmd+Opt+Esc)
4. Relaunch Fetcha
5. Verify queue state

**Expected Results**:
- Queue items preserved
- Partial downloads marked
- Option to resume or restart
- No data corruption

**Pass Criteria**: Full queue recovery

### 4.2 Disk Space Handling

#### TC-ERR-002: Insufficient Space
**Steps**:
1. Fill disk to near capacity
2. Attempt large download
3. Verify warning appears
4. Free up space
5. Retry download

**Expected Results**:
- Pre-download space check
- Clear warning message
- Prevents download start
- Succeeds after space freed

**Pass Criteria**: Disk space properly managed

## 5. Test Execution Checklist

### Pre-Release Testing Checklist

#### Environment Setup
- [ ] Clean test machine prepared
- [ ] Multiple user accounts created
- [ ] Network tools installed
- [ ] Screen recording software ready
- [ ] Bug tracking system accessible

#### Core Functionality
- [ ] Installation on clean system
- [ ] Basic download workflow
- [ ] Queue management
- [ ] Format selection
- [ ] Preferences persistence
- [ ] History tracking

#### Platform Testing
- [ ] YouTube (standard, playlist, live)
- [ ] Vimeo
- [ ] Twitter/X
- [ ] Instagram
- [ ] TikTok
- [ ] Other platforms (5+ minimum)

#### Edge Cases
- [ ] Network interruption
- [ ] Disk space exhaustion
- [ ] Invalid URLs
- [ ] Corrupted preferences
- [ ] Simultaneous operations
- [ ] Race conditions

#### System Integration
- [ ] Finder integration
- [ ] Notification Center
- [ ] QuickLook
- [ ] Default player launch
- [ ] Multi-monitor support

#### Accessibility
- [ ] Keyboard navigation
- [ ] VoiceOver support
- [ ] High contrast mode
- [ ] Zoom compatibility

#### Performance
- [ ] 100+ item queue
- [ ] 24-hour stability
- [ ] Memory monitoring
- [ ] CPU usage tracking

#### Security
- [ ] Path traversal attempts
- [ ] Cookie handling
- [ ] HTTPS verification
- [ ] Sandbox compliance

## 6. Bug Reporting Guidelines

### Bug Report Template

```
TITLE: [Component] - Brief description of issue

SEVERITY:
□ Critical - Application crash/data loss
□ High - Major feature broken
□ Medium - Feature partially broken
□ Low - Minor/cosmetic issue

ENVIRONMENT:
- macOS Version: [e.g., 14.0 Sonoma]
- Mac Model: [e.g., MacBook Pro M1 2021]
- Fetcha Version: [e.g., 1.0.0 build 100]
- yt-dlp Version: [from Debug View]
- Installation Type: [Direct/Homebrew/MacPorts]

STEPS TO REPRODUCE:
1. [Detailed step]
2. [Include exact URLs if applicable]
3. [Note timing if relevant]

EXPECTED RESULT:
[What should happen]

ACTUAL RESULT:
[What actually happened]

FREQUENCY:
□ Always (100%)
□ Often (>50%)
□ Sometimes (10-50%)
□ Rarely (<10%)
□ Once

ATTACHMENTS:
- [ ] Screenshot/Screen recording
- [ ] Debug logs (from Debug View)
- [ ] Console output
- [ ] Crash report
- [ ] Sample file/URL

WORKAROUND:
[If any exists]

ADDITIONAL NOTES:
[Any other relevant information]
```

### Severity Guidelines

**Critical**:
- Application crashes
- Data loss or corruption
- Security vulnerabilities
- Complete feature failure
- Unable to download any videos

**High**:
- Major feature non-functional
- Frequent crashes
- Performance makes app unusable
- Common use cases broken

**Medium**:
- Feature works with limitations
- Workaround available
- Infrequent crashes
- Minor data issues

**Low**:
- Cosmetic issues
- Minor inconveniences
- Edge cases
- Documentation issues

### Bug Lifecycle

1. **Discovery**: Bug found during testing
2. **Documentation**: Complete bug report filed
3. **Triage**: Developer reviews and assigns priority
4. **Investigation**: Root cause analysis
5. **Fix**: Implementation of solution
6. **Verification**: QA validates fix
7. **Regression Testing**: Ensure fix doesn't break other features
8. **Closure**: Bug marked as resolved

## 7. Release Criteria

### Go/No-Go Decision Factors

#### Must Pass (No-Go if Failed)
- [ ] All Critical bugs resolved
- [ ] All High severity bugs resolved or documented with workaround
- [ ] Core download functionality works for major platforms
- [ ] No data loss scenarios
- [ ] No security vulnerabilities
- [ ] Installation process works on clean system
- [ ] Accessibility meets WCAG 2.1 AA

#### Should Pass (Document if Failed)
- [ ] 95% of Medium severity bugs resolved
- [ ] Performance meets benchmarks
- [ ] All automated tests passing
- [ ] Memory leaks addressed
- [ ] Documentation updated

#### Nice to Have
- [ ] All Low severity bugs resolved
- [ ] UI polish complete
- [ ] All feature requests implemented
- [ ] Performance optimizations

### Sign-off Process

1. **QA Lead Sign-off**:
   - All test cases executed
   - Known issues documented
   - Risk assessment complete
   - Go/No-Go recommendation

2. **Development Lead Sign-off**:
   - Code freeze confirmed
   - All fixes verified
   - Technical debt documented

3. **Product Owner Sign-off**:
   - Features meet requirements
   - User experience acceptable
   - Business goals met

4. **Final Release Approval**:
   - All stakeholders agree
   - Release notes prepared
   - Support team briefed
   - Rollback plan ready

## 8. Post-Release Monitoring

### Day 1 Monitoring
- [ ] Crash reports monitored
- [ ] User feedback channels checked
- [ ] Social media monitored
- [ ] Support tickets triaged

### Week 1 Follow-up
- [ ] Usage analytics reviewed
- [ ] Performance metrics analyzed
- [ ] User feedback summarized
- [ ] Hot-fix planning if needed

### Continuous Improvement
- [ ] Lessons learned documented
- [ ] Test plan updated
- [ ] Automation opportunities identified
- [ ] Process improvements proposed

---

## Appendix A: Test Data

### Standard Test URLs

**YouTube**:
- Standard: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
- Playlist: `https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf`
- Short: `https://www.youtube.com/shorts/[ID]`
- Live: `https://www.youtube.com/watch?v=[LIVE_ID]`

**Vimeo**:
- Standard: `https://vimeo.com/[ID]`
- Private: `https://vimeo.com/[ID]/[HASH]`

**Other Platforms**:
- Twitter: `https://twitter.com/[user]/status/[ID]`
- Instagram: `https://www.instagram.com/p/[ID]/`
- TikTok: `https://www.tiktok.com/@[user]/video/[ID]`

### Test File Sizes
- Small: < 10MB (for quick tests)
- Medium: 100-500MB (standard testing)
- Large: 1-5GB (stress testing)
- Extreme: > 5GB (edge cases)

---

## Appendix B: Known Limitations

### Platform-Specific Issues
- Instagram may require authentication
- Facebook videos need cookies
- Some platforms require specific yt-dlp versions

### Performance Constraints
- Queue UI may lag with >500 items
- Simultaneous downloads limited by bandwidth
- Thumbnail caching uses disk space

### System Requirements
- Requires macOS 13.0 or later
- Needs internet for metadata fetching
- Some formats require ffmpeg

---

*End of QA Test Plan Document*
# fetcha.stream Testing Checklist

## Phase 4 - Testing & Polish

### ✅ Completed
- [x] Browser cookie support implemented (Safari, Chrome, Brave, Firefox, Edge)
- [x] Firefox HTTP 413 error fixed with domain filtering
- [x] UI consolidated to single view with details panel
- [x] Drag & drop queue reordering implemented
- [x] Enhanced format display with codec information
- [x] Three separate download locations (audio/video/merged)
- [x] Bundled yt-dlp and ffmpeg binaries

### 🧪 UI Testing
- [ ] URL input and auto-queue functionality
- [ ] Clipboard monitoring and auto-paste
- [ ] Queue drag & drop reordering
- [ ] Video details panel display
- [ ] Thumbnail loading
- [ ] Progress indicators
- [ ] Context menu actions
- [ ] Keyboard navigation (arrow keys, delete)
- [ ] Preferences window
- [ ] Debug console (if enabled)

### 🍪 Cookie Testing
- [ ] Safari cookie extraction
- [ ] Chrome cookie extraction
- [ ] Brave cookie extraction
- [ ] Firefox cookie extraction (with domain filter)
- [ ] Edge cookie extraction
- [ ] Private/age-restricted video access
- [ ] Cookie refresh functionality

### 📥 Download Testing
- [ ] Basic video download
- [ ] Audio-only download
- [ ] Video-only download
- [ ] Format selection
- [ ] Quality selection
- [ ] Download to separate locations
- [ ] Progress tracking
- [ ] Speed display
- [ ] ETA calculation
- [ ] Error handling
- [ ] Retry failed downloads
- [ ] Pause/resume functionality

### 🗂️ Queue Management
- [ ] Add to queue
- [ ] Remove from queue
- [ ] Clear completed
- [ ] Prioritize/deprioritize items
- [ ] Multiple concurrent downloads
- [ ] Queue persistence
- [ ] Status updates

### 📦 Binary Integration
- [ ] Bundled yt-dlp execution
- [ ] Bundled ffmpeg merging
- [ ] Binary permissions
- [ ] Error handling for missing binaries

### 🎯 Edge Cases
- [ ] Invalid URLs
- [ ] Network interruptions
- [ ] Disk space issues
- [ ] Large file downloads
- [ ] Playlist handling
- [ ] Live stream detection
- [ ] Protected content

### 🚀 Distribution Readiness
- [ ] Code signing configured
- [ ] Hardened Runtime enabled
- [ ] Entitlements set correctly
- [ ] App bundle structure verified
- [ ] Resources properly included
- [ ] Info.plist configured
- [ ] Version numbers updated

## Known Issues to Fix
1. AFIsDeviceGreymatterEligible entitlement warning (non-critical)
2. Test with actual private/age-restricted content
3. Verify all download locations work correctly
4. Ensure queue persistence across app restarts

## Next Steps (Phase 5 - Pro Features)
- Advanced metadata editing
- Batch processing
- Custom naming templates
- Post-processing scripts
- Integration with media servers
- Cloud storage support (future evolution)
# Fetcha v1.3.0 Release Notes

**Release Date:** January 2025

## 🎨 New Features

### Multi-Theme System
Fetcha now includes a complete theming system with **4 beautiful themes**:

- **OLED Black** - True black (#000000) optimized for OLED displays with maximum power savings and contrast
- **Daylight White** - Clean, bright interface (#FFFFFF) perfect for well-lit environments
- **Millennial Greige** - Warm, neutral tones (#E8E2DB) for reduced eye strain and modern aesthetics
- **Psychedelic Neon** - High-contrast neon colors (#0A0E27) for maximum visibility and creative expression

**Features:**
- Live theme switching with smooth animations
- Theme persists across app launches
- Visual theme picker with color swatches in Preferences > Appearance
- Each theme includes detailed descriptions and "best for" use cases
- All UI elements dynamically adapt to selected theme

### Enhanced Notifications
All important app events now display in the Notifications Panel:

- **Download Complete** - Confirmation when downloads finish successfully
- **Download Failed** - Error details for failed downloads
- **Dependency Updates** - Notifications for yt-dlp and ffmpeg updates
- **App Updates** - Notifications for new Fetcha versions
- Notifications accessible via bell icon in status bar
- Sliding notification panel with unread count badge

---

## 🐛 Bug Fixes

### Critical: Private Mode History Preservation
- **Fixed:** History items were being lost when toggling Private Mode on/off
- **Cause:** Dual-file system switched between `download_history.json` and `private_history.json`
- **Solution:** Single unified history file with proper Private Mode guards
- **Result:** Existing history now always persists; Private Mode only prevents NEW downloads from being recorded

### Critical: Private Mode Recording Prevention
- **Fixed:** Downloads were still being saved to history even when Private Mode was enabled
- **Cause:** Guard clause was accidentally removed during refactoring
- **Solution:** Restored early return in `addToHistory()` when Private Mode is active
- **Result:** Private Mode now properly prevents history recording

### Update Notifications Not Appearing
- **Fixed:** Dependency update notifications (yt-dlp, ffmpeg) weren't showing in UI
- **Cause:** Direct notification insertion bypassed proper notification methods
- **Solution:** Use `AppNotificationCenter.shared.addNotification()` method
- **Result:** Update notifications now properly appear in Notifications Panel with unread count

### Theme Contrast and Readability Issues
- **Fixed:** Grey sections not matching theme backgrounds
- **Fixed:** Poor text contrast in Millennial Greige theme
- **Solution:** Adjusted surface colors to match each theme's background color
- **Result:**
  - OLED Black: Even darker surfaces (opacity 0.02-0.06) for true black appearance
  - Daylight White: Much lighter surfaces (#FCFCFC-#F2F2F2) closer to pure white
  - Millennial Greige: Surfaces stay in greige tones (#E0DAD3-#C9BCA8), improved text contrast
  - Psychedelic Neon: Darker surfaces (#1F2440-#323850) better match dark background

---

## 🎯 Improvements

### OLED Display Optimization
- True black (#000000) backgrounds across entire application
- Reduced power consumption on OLED displays
- Maximum contrast for better visibility in dark environments
- Surface elements use minimal opacity (2-6%) for subtle elevation

### Theme System Architecture
- Protocol-based theme color palettes for easy extensibility
- Reactive theme manager with `@Published` properties for instant UI updates
- Centralized color definitions via `FreshUI.Colors` abstraction
- All views automatically adapt to theme changes without code modifications

### Enhanced Download History
- Downloads now tagged with `isPrivateMode` flag for potential future filtering features
- Single unified history file (`download_history.json`) for reliability
- Maintains backward compatibility with existing history data

---

## 📋 Technical Details

### Files Modified
- `yt-dlp-MAX/Services/DownloadHistory.swift` - Private Mode fixes
- `yt-dlp-MAX/Services/DependencyUpdateChecker.swift` - Notification routing fixes
- `yt-dlp-MAX/Services/DownloadQueue.swift` - Download event notifications
- `yt-dlp-MAX/Views/FreshUITheme.swift` - Complete theme system implementation
- `yt-dlp-MAX/Views/PreferencesView.swift` - Theme picker UI
- `yt-dlp-MAX/Views/*.swift` - Theme support across all panels (12 view files)
- `yt-dlp-MAX.xcodeproj/project.pbxproj` - Version number update
- `yt-dlp-MAX/Utils/AppConstants.swift` - Version number update

### New Components
- `AppTheme` enum with 4 theme cases
- `ThemeColorPalette` protocol for theme definitions
- `ThemeManager` ObservableObject for reactive theme switching
- `AppearancePreferencesView` for theme selection
- `ThemeDescriptionView` for theme preview cards

### Dependencies
No new dependencies added. All theming uses native SwiftUI and Foundation frameworks.

---

## 🚀 Upgrade Instructions

### From v1.2.x
1. Download and install v1.3.0
2. **Your history will be preserved automatically**
3. Open Preferences > Appearance to select your preferred theme
4. Private Mode now works correctly - enable it to prevent history recording
5. Check the Notifications Panel (bell icon) for update notifications

### First-Time Installation
Follow standard installation instructions. Default theme is OLED Black.

---

## ⚠️ Known Issues

### Private Mode History Migration
If you used Private Mode in v1.2.x, you may have two history files:
- `download_history.json` - Regular downloads
- `private_history.json` - Private mode downloads (will not be loaded in v1.3.0)

**Workaround:** If you need to merge private history, manually copy records from `private_history.json` to `download_history.json`. Both files are located in:
```
~/Library/Application Support/fetcha.stream/
```

### Theme Switching Performance
First theme switch after app launch may have a brief (~100ms) delay while color caches are rebuilt. Subsequent switches are instant.

---

## 🔮 Future Plans

### Upcoming in v1.4.0
- Custom theme creation
- Additional pre-built themes (Solarized, Nord, Dracula)
- Per-panel theme overrides
- Theme import/export functionality
- Private Mode history filtering (show/hide instead of delete)

---

## 📞 Support

- **Report Issues:** https://github.com/mstrslv13/fetcha/issues
- **Email Support:** dev@fetcha.stream
- **GitHub Repository:** https://github.com/mstrslv13/fetcha-stream

---

## 🙏 Acknowledgments

Thank you to all users who reported the Private Mode history bug and theme contrast issues. Your feedback makes Fetcha better!

---

## 📜 License

Fetcha is open source software. See LICENSE file for details.

---

**Full Changelog:** v1.2.0...v1.3.0

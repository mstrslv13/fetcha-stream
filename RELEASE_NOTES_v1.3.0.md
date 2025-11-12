# Release Notes - Version 1.3.0

## 🎨 Theme System Overhaul

### New Multi-Theme System
- **Complete UI theming** with reactive color updates across all panels
- **2 Production Themes Available**:
  - **OLED Black**: True black optimized for OLED displays with maximum contrast
  - **Psychedelic Neon**: High-contrast neon colors for vibrant visual experience

### Theme System Architecture
- Protocol-based color palette system for extensibility
- Reactive theme updates using `@ObservedObject` pattern
- Fixed static color references that prevented theme updates
- All UI components now properly observe theme changes
- Eliminated grey backgrounds - all surfaces match selected theme

### Theme Fixes
- Fixed history sidebar not respecting theme selection
- Fixed side panels showing incorrect colors after theme switch
- Replaced 50+ hardcoded color references with theme-aware colors
- Progress bars, backgrounds, and surfaces all use theme colors
- Fixed ScrollView default grey backgrounds across 17 components

## 🔒 Private Mode Improvements

### Fixed History Persistence Bug
- **Critical Fix**: Private Mode now correctly prevents history saving
- Restored guard clause that was accidentally removed
- Download notifications are now suppressed in Private Mode
- History items properly tagged with `isPrivateMode` flag
- No history or notifications leak when Private Mode is enabled

## 🔔 Notification System Enhancements

### Fixed Update Notifications
- Dependency update notifications now properly appear
- Fixed routing to use `AppNotificationCenter.shared.addNotification()`
- Update notifications include direct download links
- All notifications now route to NotificationsPanel

### Expanded Notification Coverage
- Download completion notifications (respects Private Mode)
- Download failure notifications with error details
- Update availability notifications with version info
- Proper notification suppression in Private Mode

## 🎛️ UI/UX Refinements

### Simplified Media Controls
- **Removed**: Previous, Next, and Stop buttons from media control bar
- **Streamlined**: Single Play button for opening downloaded files
- Cleaner, less cluttered interface
- Functionality focused on primary use case

### Invisible Panel Toggles
- Side panel toggle buttons are now invisible but fully functional
- Click areas remain active (10px × 100px zones)
- Tooltips and accessibility features preserved
- Cleaner visual appearance without visible toggle icons

### Visual Improvements
- Progress bar backgrounds now match theme
- Eliminated all grey areas that conflicted with themes
- Consistent color application across all panels
- Better visual hierarchy with theme-appropriate surfaces

## 🏗️ Technical Improvements

### Architecture Changes
- Migrated from static `FreshUI.Colors` to reactive `themeManager.colors`
- Added `@ObservedObject themeManager` to 15+ view components
- Fixed theme reactivity in nested view structs
- Proper SwiftUI state management for theme updates

### Files Modified (Major Changes)
- **Theme System**: `FreshUITheme.swift` - Complete rewrite
- **Views Updated**: 20+ view files with theme observer integration
- **Services Fixed**: `DownloadHistory.swift`, `DownloadQueue.swift`, `DependencyUpdateChecker.swift`
- **Preferences**: `PreferencesView.swift` - New Appearance section

### Performance
- No performance impact from theme system
- Efficient reactive updates using SwiftUI's observation system
- Removed unnecessary theme reference instances

## 🐛 Bug Fixes

1. **Private Mode History Leak** - Fixed history being saved when Private Mode enabled
2. **Theme Not Updating** - Fixed panels not responding to theme changes
3. **Grey Backgrounds** - Eliminated hardcoded grey colors throughout app
4. **Update Notifications Missing** - Fixed notification routing for dependency updates
5. **History Panel Black Background** - Fixed panel stuck on black regardless of theme
6. **ScrollView Backgrounds** - Added `.scrollContentBackground(.hidden)` to 17 components

## 📋 Breaking Changes

### Removed Themes
- **Daylight White** - Removed due to text visibility issues
- **Millennial Greige** - Removed due to text contrast problems
- Users on these themes will auto-switch to OLED Black

### UI Changes
- Media control bar simplified (removed navigation buttons)
- Side panel toggles now invisible (functionality unchanged)

## 🔄 Upgrade Notes

- Existing users will retain their theme preference if using OLED Black
- Users on removed themes will default to OLED Black
- All preferences and history data preserved
- No migration required

## 📝 Version Information

- **Version**: 1.3.0
- **Build Date**: 2025-11-11
- **Previous Version**: 1.2.0
- **Compatibility**: macOS 14.6+

---

## 🎯 What's Next in v1.4.0

- Additional theme refinements
- Enhanced error handling UI
- Playlist management improvements
- Performance optimizations

---

**Full Changelog**: https://github.com/mstrslv13/fetcha-stream/compare/v1.2.0...v1.3.0

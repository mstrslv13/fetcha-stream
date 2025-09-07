# Changelog

All notable changes to Fetcha Stream will be documented in this file.

## [1.2.0] - 2025-09-07

### 🎨 Major UI Overhaul & Notification System

#### ✨ New Features

##### Notification System
- **Notification Center**: Non-modal, slide-in notification panel
  - Positioned on left side near bell button for easy access
  - Cookie import success/failure notifications
  - Download completion and error notifications
  - Update availability alerts
  - Unread badge counter on bell icon
  - Clear all functionality
  - Smooth slide-in/out animations from left edge

##### Developer Tools
- **Enhanced Debug Console**: Professional bottom-sliding panel
  - Proper log ordering (newest at bottom, auto-scroll)
  - Advanced filtering: All, Error, Warn, Info, yt-dlp, ffmpeg
  - Horizontal scrolling for long log lines
  - Search functionality
  - Export logs with expanded window (650px height)
  - Copy all and clear functionality
  
- **Status Bar**: Always-visible bottom status bar
  - Settings button (opens Preferences)
  - Notifications bell with unread counter
  - Version number (clickable for About/Updates)
  - Dev Tools toggle (Alt+Cmd+I)
  - Real-time status messages

##### Cookie & Authentication
- **Cookie Extraction Notifications**: Real-time feedback
  - Success: "Safari cookies successfully imported! (X cookies)"
  - Failure: Browser-specific error messages
  - Warnings for partial extractions
  - Verbose logging in debug console, user-friendly in notifications

##### Audio Processing
- **Audio Extraction Settings**: Enhanced configuration
  - Separate folder setting for extracted audio files
  - Configurable in Preferences > Post-Processing
  - Auto-creates directory if needed
  - Maintains original video location if not configured

##### Update Management
- **Fetcha Update Check**: In Preferences > Updates
  - Shows current Fetcha version
  - Download button when update available
  - Alongside yt-dlp and ffmpeg version checks

#### 🔧 Improvements

##### UI/UX
- **Dynamic Version Management**: Centralized in AppConstants
  - Version numbers update automatically across all views
  - Single source of truth for app version
  - Used in About, Preferences, and Status Bar

- **Cleaner Interface**: Removed duplicate controls
  - Removed gear button from main URL bar
  - Settings only accessible via Status Bar
  - Streamlined top toolbar

- **Better Panel Management**: 
  - Non-modal notification panel (can interact with app while open)
  - Fixed About window singleton pattern
  - Proper window management for all panels

#### 🐛 Bug Fixes

##### Critical Fixes
- **Fixed App Closing Bug**: NotificationsPanel X button no longer closes entire app
- **Fixed Log Order**: Console logs now properly show newest at bottom
- **Fixed Text Cutoff**: Export logs window expanded to prevent text clipping
- **Fixed Notification Toggle**: Bell button properly toggles panel open/closed
- **Fixed Auto-Add**: Clipboard monitoring restored and working

##### UI Fixes
- Fixed thumbnail persistence in download history
- Fixed window toggling for Settings and About
- Fixed history panel sorting and display
- Fixed missing file indicators (container, resolution, audio)
- Fixed context menu in history panel
- Fixed interface spacing issues
- Fixed About page opening multiple windows

#### 📋 Technical Changes
- Implemented binding-based notification panel state management
- Changed logs from `insert(at: 0)` to `append` for proper ordering
- Improved StatusBar with visual feedback for active states
- Enhanced cookie extraction parsing in YTDLPService
- Added `extractedAudioPath` to AppPreferences
- Implemented proper window sizing for export views

#### 🔄 Reverted Changes
- Main interface reverted to v1.1.1 design per user request
- Kept new improvements (dev console, status bar) while maintaining original layout

## [1.1.1] - 2025-09-07

### 🎉 Major Release - Enhanced User Experience & Professional Features

#### 🚀 New Features

##### Onboarding & Setup
- **Automated Onboarding System**: Complete redesign of first-run experience
  - Automatic detection and installation of dependencies (Homebrew, yt-dlp, ffmpeg)
  - User-friendly setup wizard with clear explanations
  - Three installation options: Automated, Manual, or Skip
  - Progress tracking with visual feedback during installation
  - Cookie permission setup with browser-specific instructions

##### Error Handling & Recovery
- **Smart Error Resolution**: Intelligent error analysis with quick fixes
  - ERROR button on failed downloads shows detailed error information
  - One-click fixes for common issues (duplicate files, authentication, format errors)
  - User-friendly error messages without technical jargon
  - Automatic suggestions based on error type

##### File Management
- **Duplicate File Handling**: Automatic filename incrementing
  - Files saved as "filename (1).mp4", "filename (2).mp4" when duplicates exist
  - Configurable maximum attempts (default: 100)
  - Toggle option in Preferences > Naming section
  - Smart detection of existing files before download

##### Debug Console
- **Professional Debug Console**: Complete overhaul of logging system
  - Fully selectable and copyable text using native NSTextView
  - Advanced filtering by log type (Errors, Warnings, Info, Success, Commands)
  - Search functionality to find specific logs
  - Color-coded log levels for better readability
  - Export logs with date/time range filtering
  - Multiple export formats (Text, JSON, CSV)
  - Copy All and Clear buttons for quick actions

##### Menu Bar & UI
- **Enhanced Menu System**: Professional macOS menu structure
  - Preferences accessible from Fetcha menu (Cmd+,)
  - Tools menu with dependency checker and cache clearing
  - View menu for toggling panels
  - Help menu with quick start guide and bug reporting
  - Browser Integration Setup in Tools menu

#### 🔧 Improvements

##### Performance
- **Optimized Logging**: Dramatically reduced verbose logging
  - Removed frame-by-frame progress updates
  - Filtered out repetitive yt-dlp/ffmpeg output
  - Only important status updates, warnings, and errors logged
  - Fixes UI slowdown when debug console is open
  - Maintains all critical debugging information

##### URL Handling
- **Better URL Parsing**: Improved handling of complex URLs
  - Fixed issue with ampersands (&) in YouTube URLs
  - Proper handling of URL parameters
  - Better validation without breaking valid URLs

##### UI/UX
- **Preferences Window**: Fixed window management
  - Preferences opens in proper separate window
  - Can be closed and reopened without issues
  - Proper window tracking and state management

##### Error Messages
- **User-Friendly Errors**: Complete rewrite of error messaging
  - Clear explanations without technical terms
  - Actionable suggestions for resolution
  - Visual indicators for different error types
  - Help buttons that provide context

#### 🐛 Bug Fixes
- Fixed crash when clicking preferences gear after onboarding
- Fixed invalid SF Symbol names (sidebar.left.filled → sidebar.left)
- Fixed missing AppIcon reference crash
- Fixed preferences window not closing when opened from menu bar
- Fixed URL validation breaking on legitimate query parameters
- Fixed duplicate customOutputPath property compilation error
- Fixed String.length error (changed to String.count)

#### 📋 Technical Changes
- Implemented VectorAssociatedObject for runtime property storage
- Added NSHostingController for proper window management
- Improved Process execution with better pipe handling
- Enhanced AppleScript integration for privileged operations
- Better error propagation throughout the service layer

#### 🔒 License Change
- **New Commercial License**: Restrictive license for commercial use
  - Free for personal, educational, and non-profit use
  - Commercial use requires paid license agreement
  - Contact required for business/commercial applications
  - Protects intellectual property while maintaining open source spirit

### Breaking Changes
- License changed from GPL v3 to custom commercial license
- Minimum macOS version requirement maintained at 10.15

### Dependencies
- yt-dlp (auto-installed if missing)
- ffmpeg (auto-installed if missing)
- Homebrew (auto-installed if missing on macOS)

### Notes
This release represents a major milestone in making Fetcha Stream more accessible to non-technical users while maintaining powerful features for advanced users. The focus has been on removing friction points identified by beta testers and creating a seamless experience from installation to daily use.

---

## [1.0.0] - 2025-08-22

### Initial Release
- Basic yt-dlp GUI functionality
- Video format selection
- Download progress tracking
- Queue management
- Basic error handling
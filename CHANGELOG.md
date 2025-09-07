# Changelog

All notable changes to Fetcha Stream will be documented in this file.

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
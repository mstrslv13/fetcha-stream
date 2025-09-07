# Fetcha Stream

Fetch streaming media as easy as CMD+C! Simple, modern and powerful. Download straight from your web browser.

[<img width="153" height="153" alt="image" src="https://github.com/user-attachments/assets/c0f70713-83e4-4688-9a63-22f87681062d" />](https://buymeacoffee.com/mstrslva) [<img width="545" height="153" alt="yellow-button" src="https://github.com/user-attachments/assets/a801152e-2487-420e-bb08-96018d5b08cf" />](https://buymeacoffee.com/mstrslva)

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Version](https://img.shields.io/badge/version-1.2.0-green)
![License](https://img.shields.io/badge/license-Commercial-red)

Built with Swift and SwiftUI, Fetcha provides a beautiful native interface for yt-dlp with browser cookie support and advanced features.  The app follows the VLC model: simple for beginners, powerful when needed.

Whether you're saving tutorials for offline viewing, archiving content, or building a media library, Fetcha makes it simple. No command line knowledge required – just copy the video URL from your browser and the download will begin.

## Features

### Core Features
- 📦 **Copy and go!** - `⌘C` a video URL and... done. It's that easy.
- 🎬 **Download videos from YouTube, X** and 1000+ sites
- 📊 **Multiple quality options** - Choose your preferred resolution and container format
- 🎯 **Queue management** - Download multiple videos concurrently
- 🍪 **Browser cookie support** - Access private/age-restricted content
- 📜 **Download history** - Track and search all your downloads
- 🔒 **Privacy mode** - Download without saving history
- 🖼️ **Post-processing** - Extract audio files automatically in wav, mp3, flac, m4a, ogg, and opus formats
- ⚡ **Optimized performance** - Native SwiftUI, minimal CPU and memory usage

### New in v1.2.0
- 🔔 **Notification Center** - In-app notifications with cookie import status, errors, and updates
- 🐛 **Enhanced Debug Console** - Bottom panel with filters, proper log ordering (newest at bottom)
- 📊 **Status Bar** - Quick access to settings, notifications, version info, and dev tools
- 🍪 **Cookie Status Notifications** - Real-time feedback on browser cookie extraction
- 🎵 **Audio Extraction Settings** - Configure separate folder for extracted audio files
- 🔄 **Dynamic Version Management** - Version numbers update automatically across the app
- 📤 **Improved Log Export** - Larger export window to prevent text cutoff
- 🎯 **Non-Modal Notifications** - Interact with the app while notifications panel is open
- ✨ **UI Improvements** - Cleaner interface with removed duplicate controls

## Installation

### Quick Install (Recommended)

1. **Download Fetcha** from [Releases](https://github.com/mstrslv13/fetcha-stream/releases)
2. **Open the DMG** and drag Fetcha to your Applications folder
3. **Launch Fetcha** - it will guide you through everything else!

### First Launch Experience

When you open Fetcha for the first time, our friendly setup wizard will:

1. **Check for Required Tools** - Fetcha needs yt-dlp (the download engine) and optionally ffmpeg (for video processing)

2. **Offer Three Simple Options**:
   - **🚀 "Install Automatically"** (Recommended)
     - Just click and relax! Fetcha will:
     - Install Homebrew if needed (you'll enter your password once)
     - Install yt-dlp and ffmpeg automatically
     - Show real-time progress for each step
     - Takes about 2-3 minutes total
   
   - **📁 "Select Manually"** 
     - Already have these tools? Just point Fetcha to where they're installed
     - Useful for custom installations or if you prefer managing tools yourself
   
   - **⏭️ "Skip"**
     - Continue without ffmpeg (some features limited)
     - Note: yt-dlp is required for Fetcha to work

3. **Optional: Browser Cookies**
   - Grant permission for Fetcha to use your browser cookies
   - This lets you download private or age-restricted videos
   - You can always set this up later in Preferences

4. **You're Ready!** 
   - That's it! No command line, no technical knowledge needed
   - Just copy any video URL and Fetcha handles the rest

### Manual Installation (Advanced Users)

If you prefer to install dependencies manually:

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install yt-dlp (required)
brew install yt-dlp

# Install ffmpeg (recommended)
brew install ffmpeg
```

Then download and install Fetcha from the releases page.

## Building from Source

### Requirements
- Xcode 15.0 or later
- macOS 15.0 or later

### Build Steps

1. Clone the repository:
```bash
git clone https://github.com/mstrslv13/fetcha-stream.git
cd fetcha
```

2. Open in Xcode:
```bash
open yt-dlp-MAX.xcodeproj
```

3. Build and run (⌘R)

## Usage

1. **Add a video**: Copy a Youtube URL and Fetcha automates the rest
2. **Select quality**: Choose your preferred format in preferences
3. **Queue downloads**: Add multiple videos to download concurrently
4. **Monitor progress**: Track downloads in real-time
5. **Access history**: View and search all past downloads

### Keyboard Shortcuts

- `⌘C` - Copy URL
- `⌘V` - Paste URL
- `⌘,` - Open Preferences
- `⌘H` - Toggle History Panel
- `⌘D` - Toggle Details Panel
- `⌘⇧P` - Toggle Privacy Mode

## Privacy Mode

Enable Privacy Mode to:
- Prevent saving download history
- Clear clipboard monitoring
- Remove temporary data after downloads

## Browser Cookie Support

Fetcha can use cookies from your installed browsers to download:
- Private videos
- Age-restricted content
- Member-only content

Supported browsers:
- Safari
- Chrome
- Firefox
- Brave
- Edge

## Troubleshooting

### "yt-dlp not found" error
Make sure yt-dlp is installed and in your PATH:
```bash
which yt-dlp
```

### Videos won't merge audio/video
Install ffmpeg for automatic merging:
```bash
brew install ffmpeg
```

### App won't open
Right-click the app and select "Open", then click "Open" in the dialog.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This software uses a dual licensing model:
- **Free** for personal, educational, and non-profit use
- **Commercial license required** for business use

See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [FFmpeg](https://ffmpeg.org/) - For media processing

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/mstrslv13/fetcha-stream/issues) page.

---

**Fetcha** - Simple for beginners, powerful for nerds.

# Fetcha

Fetch streaming media as easy as CMD+C! Simple, modern and powerful. Download straight from your web browser.

[<img width="153" height="153" alt="image" src="https://github.com/user-attachments/assets/c0f70713-83e4-4688-9a63-22f87681062d" />](https://buymeacoffee.com/mstrslva) [<img width="545" height="153" alt="yellow-button" src="https://github.com/user-attachments/assets/a801152e-2487-420e-bb08-96018d5b08cf" />](https://buymeacoffee.com/mstrslva)

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Version](https://img.shields.io/badge/version-1.0-green)

Built with Swift and SwiftUI, Fetcha provides a beautiful native interface for yt-dlp with browser cookie support and advanced features.  The app follows the VLC model: simple for beginners, powerful when needed.

Whether you're saving tutorials for offline viewing, archiving content, or building a media library, Fetcha makes it simple. No command line knowledge required – just copy the video URL from your browser and the download will begin.
## Features

- 🎬 **Download videos from YouTube, X** and 1000+ sites
- 📊 **Multiple quality options** - Choose your preferred resolution and container format
- 🎯 **Queue management** - Download multiple videos concurrently
- 🍪 **Browser cookie support** - Access private/age-restricted content
- 📜 **Download history** - Track and search all your downloads
- 🔒 **Privacy mode** - Download without saving history
- 🖼️ **Post-processing** - Extract audio files automatically in wav, mp3, flac, m4a, ogg, and opus formats
- ⚡ **Optimized performance** - Native SwiftUI, minimal CPU and memory usage

## Installation

### Prerequisites

1. **Install Homebrew** (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Install yt-dlp**:
```bash
brew install yt-dlp
```

3. **Install ffmpeg** (optional but recommended):
```bash
brew install ffmpeg
```

### Download Fetcha

1. Download the latest release from [Releases](https://github.com/mstrslv13/fetcha/releases)
2. Open the DMG file and drag Fetcha to your Applications folder
3. On first launch, you may need to right-click and select "Open" to bypass Gatekeeper

## Building from Source

### Requirements
- Xcode 15.0 or later
- macOS 15.0 or later

### Build Steps

1. Clone the repository:
```bash
git clone https://github.com/mstrslv13/fetcha.git
cd fetcha
```

2. Open in Xcode:
```bash
open yt-dlp-MAX.xcodeproj
```

3. Build and run (⌘R)

## Usage

1. **Add a video**: Paste a YouTube URL into the input field
2. **Select quality**: Choose your preferred format from the dropdown
3. **Queue downloads**: Add multiple videos to download concurrently
4. **Monitor progress**: Track downloads in real-time
5. **Access history**: View and search all past downloads

### Keyboard Shortcuts

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [FFmpeg](https://ffmpeg.org/) - For media processing

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/mstrslv13/fetcha/issues) page.

---

**Fetcha** - Simple for beginners, powerful when needed.

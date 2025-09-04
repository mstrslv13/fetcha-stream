# Fetcha

<div align="center">
  <img src="/Users/mstrslv/devspace/fetcha-website/logo.svg" width="100" alt="Fetcha Logo" />
  <br/>
  <br/>
  <a href="https://buymeacoffee.com/mstrslva">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=mstrslva&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" />
  </a>
</div>

<br/>

A modern, native macOS application for downloading videos with a clean and intuitive interface. Built with Swift and SwiftUI, Fetcha provides a powerful GUI for yt-dlp with browser cookie support and advanced features. Visit our official website at [fetcha.stream](https://fetcha.stream).

![macOS](https://img.shields.io/badge/macOS-11.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)

## ✨ Features

### Core Functionality
- 🎥 **Smart Format Selection** - Automatically selects the best quality or lets you choose
- 🍪 **Browser Cookie Support** - Download private/age-restricted videos using cookies from Safari, Chrome, Brave, Firefox, and Edge
- 📦 **Queue Management** - Drag & drop reordering, concurrent downloads, and smart prioritization
- 🎯 **Multiple Download Locations** - Separate folders for audio, video, and merged files
- 📊 **Real-time Progress** - Live speed, ETA, and progress tracking
- 🔄 **Auto-paste from Clipboard** - Automatically detects and queues URLs

### UI/UX
- 🎨 **Modern SwiftUI Interface** - Clean, native macOS design
- 📱 **Video Details Panel** - Thumbnails, metadata, and format information
- ⌨️ **Keyboard Navigation** - Arrow keys and shortcuts for power users
- 🔍 **Debug Console** - Built-in debugging tools for troubleshooting

### Technical
- 📦 **Self-contained** - Includes yt-dlp and ffmpeg, no dependencies needed
- 🔒 **Secure** - Hardened runtime with proper entitlements
- 🚀 **Fast** - Native Swift performance with efficient process management

## 🚀 Installation

### Option 1: Download Release (Recommended)
1. Download the latest `.dmg` from [Releases](https://github.com/yourusername/fetcha/releases)
2. Open the DMG and drag Fetcha to Applications
3. On first launch, right-click and select "Open" to bypass Gatekeeper

### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/yourusername/fetcha.git
cd fetcha

# Open in Xcode
open yt-dlp-MAX.xcodeproj

# Build and run (⌘+R)
```

## 🎯 Usage

1. **Paste a URL** - Copy any video URL and paste it into the app
2. **Select Format** - Choose quality and format (or use auto-selection)
3. **Download** - Click download or enable auto-queue for instant downloads
4. **Manage Queue** - Drag to reorder, right-click for options

### Browser Cookie Support
To download private or age-restricted videos:
1. Log into the video platform in your browser
2. Select the browser in Preferences
3. The app will automatically use your browser's cookies

## 🏗️ Architecture

```
Fetcha/
├── Models/           # Data structures (VideoInfo, DownloadTask)
├── Views/            # SwiftUI components
├── Services/         # Business logic (YTDLPService, DownloadQueue)
├── Resources/        # Bundled binaries (yt-dlp, ffmpeg)
└── docs/            # Documentation
```

The app follows MVVM architecture with:
- **Reactive UI** using Combine and SwiftUI
- **Event-driven architecture** for future extensibility
- **Storage abstraction** for cloud provider integration
- **Clean separation** of concerns

## 🔮 Roadmap

### Phase 5 - Pro Features (Next)
- [ ] Advanced metadata editing
- [ ] Batch processing from playlists
- [ ] Custom naming templates
- [ ] Post-processing scripts

### Future Evolution
- **Stage A**: API server for automation
- **Stage B**: Cloud storage integration (Dropbox, Google Drive, S3)
- **Stage C**: Semantic search with AI
- **Stage D**: Media server replacement (Jellyfin/Plex alternative)

See [FUTURE_EVOLUTION.md](docs/FUTURE_EVOLUTION.md) for detailed plans.

## 🛠️ Development

### Requirements
- macOS 11.0+
- Xcode 13+
- Swift 5.0+

### Building
```bash
# Debug build
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX -configuration Debug

# Release build
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX -configuration Release

# Package for distribution
./package_for_distribution.sh
```

### Testing
```bash
# Run tests
xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX

# Test cookies
./test_cookies.sh
```

## 📝 Contributing

Contributions are welcome! Please read [ARCHITECTURE_PRINCIPLES.md](docs/ARCHITECTURE_PRINCIPLES.md) before contributing to understand the codebase structure and design principles.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)** due to its inclusion of GPL-licensed FFmpeg components. See the [LICENSE](LICENSE) file for full details.

### Why GPL-3.0?
The application bundles FFmpeg binaries compiled with GPL-licensed codecs (libx264, libx265), requiring the entire distribution to comply with GPL terms.

### FFmpeg Attribution
This software uses code of FFmpeg licensed under the GPLv2+ and its source can be downloaded from https://github.com/FFmpeg/FFmpeg

## 🙏 Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [ffmpeg](https://ffmpeg.org/) - Media processing
- SwiftUI community for inspiration and examples

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/fetcha/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/fetcha/discussions)

---

<div align="center">
  <br/>
  <img src="/Users/mstrslv/devspace/fetcha-website/logo.svg" width="80" alt="Fetcha Logo" />
  <br/>
  <br/>
  <a href="https://buymeacoffee.com/mstrslva">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=mstrslva&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" />
  </a>
  <br/>
  <br/>
  Built with ❤️ using Swift and SwiftUI
</div>
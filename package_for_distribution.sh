#!/bin/bash

# fetcha.stream (yt-dlp-MAX) Distribution Packaging Script
# This script packages the app for distribution without Apple enrollment

echo "======================================="
echo "fetcha.stream Distribution Packager"
echo "======================================="

# Check if the app exists
if [ ! -d "build/Release/yt-dlp-MAX.app" ]; then
    echo "❌ Error: App not found at build/Release/yt-dlp-MAX.app"
    echo "Please build the app in Release mode first using Xcode"
    exit 1
fi

# Create distribution directory
DIST_DIR="dist"
APP_NAME="fetcha.stream"
<<<<<<< Updated upstream
VERSION="0.9.0"
=======
VERSION="0.9.6"
>>>>>>> Stashed changes
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_NAME="${APP_NAME}_v${VERSION}_${TIMESTAMP}"

echo "📦 Creating distribution package..."
mkdir -p "$DIST_DIR"

# Copy the app
echo "📁 Copying app bundle..."
cp -R "build/Release/yt-dlp-MAX.app" "$DIST_DIR/${APP_NAME}.app"

# Sign the bundled binaries with ad-hoc signature
echo "🔏 Signing bundled binaries..."
codesign --force --deep --sign - "$DIST_DIR/${APP_NAME}.app/Contents/Resources/bin/yt-dlp"
codesign --force --deep --sign - "$DIST_DIR/${APP_NAME}.app/Contents/Resources/bin/ffmpeg"
codesign --force --deep --sign - "$DIST_DIR/${APP_NAME}.app/Contents/Resources/bin/ffprobe"

# Sign the app with ad-hoc signature (for unsigned distribution)
echo "🔏 Signing app with ad-hoc signature..."
codesign --force --deep --sign - --options runtime --entitlements yt-dlp-MAX/yt-dlp-MAX.entitlements "$DIST_DIR/${APP_NAME}.app"

# Verify the signature
echo "✅ Verifying signature..."
codesign --verify --verbose "$DIST_DIR/${APP_NAME}.app"

# Create a DMG for easy distribution
echo "💿 Creating DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$DIST_DIR" -ov -format UDZO "$DIST_DIR/${OUTPUT_NAME}.dmg"

# Create a ZIP for alternative distribution
echo "🗜️ Creating ZIP..."
cd "$DIST_DIR"
zip -r "${OUTPUT_NAME}.zip" "${APP_NAME}.app"
cd ..

# Create README for users
cat > "$DIST_DIR/README.txt" << EOF
fetcha.stream - Modern YouTube Downloader for macOS
====================================================

Version: $VERSION
Build Date: $(date)

INSTALLATION INSTRUCTIONS:
-------------------------
1. Drag fetcha.stream.app to your Applications folder
2. On first launch, you may see a security warning
3. Go to System Preferences > Security & Privacy
4. Click "Open Anyway" to allow the app to run
5. The app includes all necessary dependencies (yt-dlp, ffmpeg)

FEATURES:
---------
• Clean, modern interface
• Browser cookie support for private videos
• Multiple quality options
• Drag & drop queue management
• Concurrent downloads
• Automatic audio/video merging

BROWSER COOKIE SUPPORT:
----------------------
The app can use cookies from:
• Safari
• Chrome
• Brave
• Firefox
• Edge

This allows downloading private or age-restricted videos.

TROUBLESHOOTING:
---------------
If the app won't open:
1. Right-click the app and select "Open"
2. Click "Open" in the dialog that appears
3. If still blocked, check Security & Privacy settings

For support, visit: https://github.com/fetcha-stream

EOF

# Calculate checksums
echo "🔐 Calculating checksums..."
shasum -a 256 "$DIST_DIR/${OUTPUT_NAME}.dmg" > "$DIST_DIR/${OUTPUT_NAME}.dmg.sha256"
shasum -a 256 "$DIST_DIR/${OUTPUT_NAME}.zip" > "$DIST_DIR/${OUTPUT_NAME}.zip.sha256"

# Final report
echo ""
echo "======================================="
echo "✅ Distribution package created successfully!"
echo "======================================="
echo ""
echo "📦 Package contents:"
echo "  • $DIST_DIR/${APP_NAME}.app - The application"
echo "  • $DIST_DIR/${OUTPUT_NAME}.dmg - DMG installer"
echo "  • $DIST_DIR/${OUTPUT_NAME}.zip - ZIP archive"
echo "  • $DIST_DIR/README.txt - Installation instructions"
echo ""
echo "📋 Checksums:"
cat "$DIST_DIR/${OUTPUT_NAME}.dmg.sha256"
cat "$DIST_DIR/${OUTPUT_NAME}.zip.sha256"
echo ""
echo "🚀 Ready for distribution!"
echo ""
echo "⚠️  Important: Since this is unsigned, users will need to:"
echo "  1. Right-click and select 'Open' on first launch"
echo "  2. Or allow it in System Preferences > Security & Privacy"
echo ""
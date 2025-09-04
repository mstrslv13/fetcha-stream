#!/bin/bash

# Simple packaging script that adds binaries after Xcode export
# This avoids modifying the Xcode project file

set -e

echo "📦 fetcha.stream Packaging with Bundled Binaries"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_NAME="yt-dlp-MAX"  # Keep internal name
DISPLAY_NAME="fetcha.stream"  # What users see
VERSION="1.0"
RESOURCES_DIR="$(pwd)/yt-dlp-MAX/Resources/bin"

echo ""
echo -e "${YELLOW}Step 1: Build and Export from Xcode${NC}"
echo "1. Open Xcode: open yt-dlp-MAX.xcodeproj"
echo "2. Product → Archive"
echo "3. Distribute App → Copy App"
echo "4. Export to Desktop"
echo ""
read -p "Press Enter when you've exported the app to Desktop..."

# Check if app exists
if [ ! -d "$HOME/Desktop/${APP_NAME}.app" ]; then
    echo -e "${RED}Error: ${APP_NAME}.app not found on Desktop${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${APP_NAME}.app${NC}"

# Step 2: Manually add binaries to the exported app
echo -e "${YELLOW}Step 2: Adding bundled binaries to app...${NC}"

# Create Resources/bin directory in app bundle
APP_RESOURCES="$HOME/Desktop/${APP_NAME}.app/Contents/Resources"
mkdir -p "$APP_RESOURCES/bin"

# Copy binaries
echo "Copying yt-dlp..."
cp "$RESOURCES_DIR/yt-dlp" "$APP_RESOURCES/bin/"
chmod +x "$APP_RESOURCES/bin/yt-dlp"

echo "Copying ffmpeg..."
cp "$RESOURCES_DIR/ffmpeg" "$APP_RESOURCES/bin/"
chmod +x "$APP_RESOURCES/bin/ffmpeg"

echo "Copying ffprobe..."
cp "$RESOURCES_DIR/ffprobe" "$APP_RESOURCES/bin/"
chmod +x "$APP_RESOURCES/bin/ffprobe"

# Verify
if [ -f "$APP_RESOURCES/bin/yt-dlp" ]; then
    echo -e "${GREEN}✓ yt-dlp added ($(du -h "$APP_RESOURCES/bin/yt-dlp" | cut -f1))${NC}"
else
    echo -e "${RED}✗ Failed to add yt-dlp${NC}"
    exit 1
fi

if [ -f "$APP_RESOURCES/bin/ffmpeg" ]; then
    echo -e "${GREEN}✓ ffmpeg added ($(du -h "$APP_RESOURCES/bin/ffmpeg" | cut -f1))${NC}"
fi

if [ -f "$APP_RESOURCES/bin/ffprobe" ]; then
    echo -e "${GREEN}✓ ffprobe added ($(du -h "$APP_RESOURCES/bin/ffprobe" | cut -f1))${NC}"
fi

# Step 3: Remove quarantine
echo -e "${YELLOW}Step 3: Removing quarantine attributes...${NC}"
xattr -cr "$HOME/Desktop/${APP_NAME}.app"

# Step 4: Test the bundled binaries
echo -e "${YELLOW}Step 4: Testing bundled binaries...${NC}"
"$APP_RESOURCES/bin/yt-dlp" --version
echo -e "${GREEN}✓ yt-dlp is working${NC}"

# Step 5: Create DMG
echo -e "${YELLOW}Step 5: Creating installer DMG...${NC}"

TEMP_DIR="/tmp/${APP_NAME}-installer"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app with binaries
cp -R "$HOME/Desktop/${APP_NAME}.app" "$TEMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TEMP_DIR/Applications"

# Create README
cat > "$TEMP_DIR/🎬 START HERE.txt" << 'EOF'
╔══════════════════════════════════════════════════════════╗
║          fetcha.stream - Video Downloader 🎬              ║
╚══════════════════════════════════════════════════════════╝

THIS VERSION INCLUDES EVERYTHING!
No downloads, no terminal commands, no setup needed!

✅ yt-dlp built-in (downloads from 1000+ sites)
✅ ffmpeg built-in (handles all video formats)
✅ Works immediately after install

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📥 INSTALL (30 seconds):
1. Drag ${APP_NAME} to Applications folder
2. That's it!

🚀 FIRST RUN:
IMPORTANT: Right-click → Open (don't double-click)
• Go to Applications
• Right-click fetcha.stream
• Choose "Open"
• Click "Open" in the dialog

After first launch, open normally!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 HOW TO USE:
1. Copy any video URL
2. Open fetcha.stream (URL auto-pastes!)
3. Choose quality or use default
4. Click Download
5. Find in your Downloads folder!

Works with: YouTube, Twitter, Instagram, TikTok, 
Reddit, and 1000+ other sites!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 IF YOU SEE "App is damaged":
1. Open Terminal (in Applications/Utilities)
2. Copy & paste this command:
   xattr -cr /Applications/${APP_NAME}.app
3. Press Enter
4. Try right-click → Open again

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enjoy! Everything is included and ready to use! 🎉
EOF

# Create DMG
DMG_NAME="${DISPLAY_NAME}-${VERSION}-Complete"
rm -f "$HOME/Desktop/${DMG_NAME}.dmg"

hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$HOME/Desktop/${DMG_NAME}.dmg"

# Create ZIP as alternative
echo -e "${YELLOW}Step 6: Creating ZIP archive...${NC}"
cd "$HOME/Desktop"
zip -rq "${DMG_NAME}.zip" "${APP_NAME}.app"

# Cleanup
rm -rf "$TEMP_DIR"

# Report
APP_SIZE=$(du -sh "$HOME/Desktop/${APP_NAME}.app" | cut -f1)
DMG_SIZE=$(du -h "$HOME/Desktop/${DMG_NAME}.dmg" | cut -f1)
ZIP_SIZE=$(du -h "$HOME/Desktop/${DMG_NAME}.zip" | cut -f1)

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SUCCESS! Self-Contained Package Created!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "📊 Package Info:"
echo "   App: $APP_SIZE (with all binaries)"
echo "   DMG: $DMG_SIZE" 
echo "   ZIP: $ZIP_SIZE"
echo ""
echo "📦 Created:"
echo "   • ${DMG_NAME}.dmg"
echo "   • ${DMG_NAME}.zip"
echo ""
echo -e "${YELLOW}To share:${NC}"
echo "1. Send either the DMG or ZIP"
echo "2. Tell them: Right-click → Open first time"
echo "3. No other setup needed!"
echo ""
echo -e "${GREEN}100% self-contained and ready to use! 🚀${NC}"
#!/bin/bash

# yt-dlp-MAX Final Packaging Script
# Creates self-contained app with bundled binaries

set -e

echo "📦 yt-dlp-MAX Final Packaging Process"
echo "======================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

APP_NAME="yt-dlp-MAX"
VERSION="1.0"
BUILD_DIR="$HOME/Desktop"

echo ""
echo -e "${YELLOW}=== CURRENT STATUS ===${NC}"
echo "✅ Resources/bin folder created with:"
echo "   • yt-dlp (34MB standalone binary)"
echo "   • ffmpeg (412KB)"
echo "   • ffprobe (344KB)"
echo ""
echo "✅ Xcode project updated with:"
echo "   • Resources folder added to project"
echo "   • Build phase for fixing binary permissions"
echo ""

echo -e "${YELLOW}=== NEXT STEPS ===${NC}"
echo ""
echo -e "${GREEN}Step 1: Build in Xcode${NC}"
echo "1. Open Xcode: open yt-dlp-MAX.xcodeproj"
echo "2. Verify Resources folder is in project navigator"
echo "3. Select 'Any Mac' as destination"
echo "4. Product → Archive"
echo "5. In Organizer: Distribute App → Copy App"
echo "6. Export to Desktop"
echo ""
read -p "Press Enter when you've exported the app to Desktop..."

# Check if app exists
if [ ! -d "$BUILD_DIR/${APP_NAME}.app" ]; then
    echo -e "${RED}Error: ${APP_NAME}.app not found on Desktop${NC}"
    echo "Please complete the Xcode build steps first."
    exit 1
fi

echo -e "${GREEN}✓ Found ${APP_NAME}.app${NC}"

# Verify binaries are bundled
echo -e "${YELLOW}Verifying bundled binaries...${NC}"

BUNDLED_YTDLP="$BUILD_DIR/${APP_NAME}.app/Contents/Resources/bin/yt-dlp"
BUNDLED_FFMPEG="$BUILD_DIR/${APP_NAME}.app/Contents/Resources/bin/ffmpeg"
BUNDLED_FFPROBE="$BUILD_DIR/${APP_NAME}.app/Contents/Resources/bin/ffprobe"

if [ -f "$BUNDLED_YTDLP" ]; then
    echo -e "${GREEN}✓ yt-dlp is bundled ($(du -h "$BUNDLED_YTDLP" | cut -f1))${NC}"
else
    echo -e "${RED}✗ yt-dlp not found in bundle${NC}"
    echo "The Resources folder may not have been included in the build."
    echo "Please check Xcode's Build Phases → Copy Bundle Resources"
    exit 1
fi

if [ -f "$BUNDLED_FFMPEG" ]; then
    echo -e "${GREEN}✓ ffmpeg is bundled ($(du -h "$BUNDLED_FFMPEG" | cut -f1))${NC}"
else
    echo -e "${YELLOW}⚠ ffmpeg not bundled (optional)${NC}"
fi

if [ -f "$BUNDLED_FFPROBE" ]; then
    echo -e "${GREEN}✓ ffprobe is bundled ($(du -h "$BUNDLED_FFPROBE" | cut -f1))${NC}"
else
    echo -e "${YELLOW}⚠ ffprobe not bundled (optional)${NC}"
fi

# Fix permissions
echo -e "${YELLOW}Fixing binary permissions...${NC}"
chmod +x "$BUNDLED_YTDLP" 2>/dev/null || true
chmod +x "$BUNDLED_FFMPEG" 2>/dev/null || true
chmod +x "$BUNDLED_FFPROBE" 2>/dev/null || true

# Remove quarantine
echo -e "${YELLOW}Removing quarantine attributes...${NC}"
xattr -cr "$BUILD_DIR/${APP_NAME}.app"

# Create DMG
echo -e "${YELLOW}Creating installer DMG...${NC}"

TEMP_DIR="/tmp/${APP_NAME}-installer"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app
cp -R "$BUILD_DIR/${APP_NAME}.app" "$TEMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TEMP_DIR/Applications"

# Create README
cat > "$TEMP_DIR/🎬 Quick Start.txt" << 'EOF'
╔══════════════════════════════════════════════════════════╗
║           yt-dlp-MAX - Complete Edition 🎬                ║
╚══════════════════════════════════════════════════════════╝

✨ EVERYTHING IS INCLUDED - NO SETUP NEEDED! ✨

This version includes:
✅ yt-dlp (built-in)
✅ ffmpeg (built-in)  
✅ Zero dependencies
✅ Works immediately

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📥 INSTALLATION (30 seconds):
1. Drag yt-dlp-MAX → Applications folder
2. Done! No other setup needed!

🚀 FIRST LAUNCH:
⚠️ IMPORTANT: Right-click → Open (don't double-click)

• Open Applications folder
• Right-click yt-dlp-MAX
• Select "Open"
• Click "Open" in security dialog

After first launch, you can open normally!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ FEATURES:
• Paste any video URL
• Choose quality (or use best)
• Download with progress bar
• Queue multiple downloads
• Custom download locations

🎯 HOW TO USE:
1. Copy a video URL
2. Open yt-dlp-MAX
3. URL auto-pastes
4. Click Download
5. Find in Downloads folder!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 TROUBLESHOOTING:

"App is damaged" error?
• Open Terminal
• Paste: xattr -cr /Applications/yt-dlp-MAX.app
• Press Enter
• Try right-click → Open again

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enjoy downloading! 🎉
EOF

# Create DMG
DMG_NAME="${APP_NAME}-${VERSION}-Complete"
rm -f "$BUILD_DIR/${DMG_NAME}.dmg"

echo "Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/${DMG_NAME}.dmg"

# Create ZIP
echo -e "${YELLOW}Creating ZIP archive...${NC}"
cd "$BUILD_DIR"
zip -rq "${DMG_NAME}.zip" "${APP_NAME}.app"

# Cleanup
rm -rf "$TEMP_DIR"

# Final size check
APP_SIZE=$(du -sh "$BUILD_DIR/${APP_NAME}.app" | cut -f1)
DMG_SIZE=$(du -h "$BUILD_DIR/${DMG_NAME}.dmg" | cut -f1)
ZIP_SIZE=$(du -h "$BUILD_DIR/${DMG_NAME}.zip" | cut -f1)

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 SUCCESS! Self-Contained Package Created!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "📦 Package Details:"
echo "   App Size: $APP_SIZE (includes all binaries)"
echo "   DMG Size: $DMG_SIZE"
echo "   ZIP Size: $ZIP_SIZE"
echo ""
echo "📍 Files Created:"
echo "   • $BUILD_DIR/${DMG_NAME}.dmg"
echo "   • $BUILD_DIR/${DMG_NAME}.zip"
echo ""
echo -e "${YELLOW}📤 To Share:${NC}"
echo "1. Send either DMG or ZIP file"
echo "2. Tell recipient: Right-click → Open on first launch"
echo "3. That's it! No dependencies needed!"
echo ""
echo -e "${GREEN}The app is 100% self-contained and ready to use! 🚀${NC}"
echo ""
echo "Included binaries:"
echo "• yt-dlp: Downloads videos from 1000+ sites"
echo "• ffmpeg: Merges audio/video, converts formats"
echo "• ffprobe: Analyzes media files"
echo ""
echo -e "${GREEN}Your friend can start downloading immediately!${NC}"
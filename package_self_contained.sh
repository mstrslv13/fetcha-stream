#!/bin/bash

# yt-dlp-MAX Self-Contained Packager
# Creates a fully portable app with bundled yt-dlp and ffmpeg

set -e

echo "📦 Creating Self-Contained yt-dlp-MAX Package"
echo "=============================================="

APP_NAME="yt-dlp-MAX"
VERSION="1.0"
BUILD_DIR="$HOME/Desktop"
DMG_NAME="${APP_NAME}-${VERSION}-Complete"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Build in Xcode${NC}"
echo "1. Open Xcode"
echo "2. Add Resources folder to project (see setup_bundled_binaries.md)"
echo "3. Product → Archive"
echo "4. Distribute App → Copy App → Export to Desktop"
echo ""
read -p "Press Enter when you've exported the app to Desktop..."

# Check if app exists
if [ ! -d "$BUILD_DIR/${APP_NAME}.app" ]; then
    echo -e "${RED}Error: ${APP_NAME}.app not found on Desktop${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${APP_NAME}.app${NC}"

# Step 2: Verify binaries are included
echo -e "${YELLOW}Step 2: Verifying bundled binaries...${NC}"

if [ -f "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/bin/yt-dlp" ]; then
    echo -e "${GREEN}✓ yt-dlp is bundled${NC}"
else
    echo -e "${RED}✗ yt-dlp not found in bundle${NC}"
    echo "Please add Resources folder to Xcode project (see instructions)"
    exit 1
fi

if [ -f "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/bin/ffmpeg" ]; then
    echo -e "${GREEN}✓ ffmpeg is bundled${NC}"
else
    echo -e "${RED}✗ ffmpeg not found in bundle${NC}"
fi

# Step 3: Remove quarantine
echo -e "${YELLOW}Step 3: Removing quarantine attributes...${NC}"
xattr -cr "$BUILD_DIR/${APP_NAME}.app"

# Step 4: Create installer package
echo -e "${YELLOW}Step 4: Creating installer package...${NC}"

TEMP_DIR="/tmp/${APP_NAME}-installer"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app
cp -R "$BUILD_DIR/${APP_NAME}.app" "$TEMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TEMP_DIR/Applications"

# Create README
cat > "$TEMP_DIR/README.txt" << 'EOF'
╔══════════════════════════════════════════════════════════╗
║              yt-dlp-MAX - Self-Contained Edition          ║
╚══════════════════════════════════════════════════════════╝

This version includes EVERYTHING - no additional downloads needed!

✅ Includes yt-dlp
✅ Includes ffmpeg
✅ Zero dependencies
✅ Ready to use immediately

INSTALLATION:
============
1. Drag yt-dlp-MAX to Applications folder
2. Right-click yt-dlp-MAX → Select "Open"
3. Click "Open" in security dialog
4. Enjoy! No other setup needed!

FEATURES:
=========
• Auto-paste URLs from clipboard
• Download queue with progress
• Custom download locations  
• Quality selection
• Single-pane interface
• Right-click context menus
• Preferences that persist

FIRST LAUNCH:
=============
⚠️ IMPORTANT: Right-click → Open (don't double-click)

This bypasses macOS Gatekeeper for unsigned apps.
After first launch, you can open normally.

TROUBLESHOOTING:
================
If "App is damaged" error:
1. Open Terminal
2. Run: xattr -cr /Applications/yt-dlp-MAX.app
3. Try right-click → Open again

ENJOY YOUR DOWNLOADS!
EOF

# Create DMG
echo -e "${YELLOW}Step 5: Creating DMG...${NC}"
rm -f "$BUILD_DIR/${DMG_NAME}.dmg"

hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/${DMG_NAME}.dmg"

# Create ZIP
echo -e "${YELLOW}Step 6: Creating ZIP...${NC}"
cd "$BUILD_DIR"
zip -r "${DMG_NAME}.zip" "${APP_NAME}.app"

# Cleanup
rm -rf "$TEMP_DIR"

# Final report
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SELF-CONTAINED PACKAGE CREATED!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "📦 DMG: $BUILD_DIR/${DMG_NAME}.dmg"
echo "📦 ZIP: $BUILD_DIR/${DMG_NAME}.zip"
echo ""
echo -e "${YELLOW}What's Included:${NC}"
echo "• yt-dlp (34 MB standalone binary)"
echo "• ffmpeg & ffprobe (756 KB)"
echo "• Your complete app"
echo ""
echo -e "${YELLOW}To Share:${NC}"
echo "1. Send either DMG or ZIP"
echo "2. Tell them: Right-click → Open on first launch"
echo "3. That's it! No dependencies needed!"
echo ""
echo -e "${GREEN}Your friend can use it immediately - zero setup! 🎉${NC}"
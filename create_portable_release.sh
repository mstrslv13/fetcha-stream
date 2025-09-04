#!/bin/bash

# yt-dlp-MAX Portable Release Creator
# Creates a distributable DMG without Apple signing

set -e

echo "🚀 Creating Portable yt-dlp-MAX Release"
echo "========================================"

# Configuration
APP_NAME="yt-dlp-MAX"
VERSION="1.0"
EXPORT_PATH="$HOME/Desktop/${APP_NAME}-Export"
DMG_PATH="$HOME/Desktop"
TEMP_DIR="/tmp/yt-dlp-MAX-dmg"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Looking for exported app...${NC}"
echo "After archiving in Xcode, export the app to your Desktop"
echo "Expected location: $HOME/Desktop/${APP_NAME}.app"

# Check if app exists
if [ ! -d "$HOME/Desktop/${APP_NAME}.app" ]; then
    echo "App not found at $HOME/Desktop/${APP_NAME}.app"
    echo "Please export from Xcode first (Product → Archive → Distribute App → Copy App)"
    exit 1
fi

echo -e "${GREEN}✓ Found ${APP_NAME}.app${NC}"

# Step 2: Remove quarantine attributes (important!)
echo -e "${YELLOW}Step 2: Removing quarantine attributes...${NC}"
xattr -cr "$HOME/Desktop/${APP_NAME}.app"

# Step 3: Create DMG structure
echo -e "${YELLOW}Step 3: Creating DMG structure...${NC}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app
cp -R "$HOME/Desktop/${APP_NAME}.app" "$TEMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TEMP_DIR/Applications"

# Create installer background and instructions
cat > "$TEMP_DIR/READ ME FIRST.txt" << 'EOF'
═══════════════════════════════════════════════════════════
                    yt-dlp-MAX Installation
═══════════════════════════════════════════════════════════

IMPORTANT: This app is unsigned for direct distribution.
Follow these steps to install:

1. INSTALLATION:
   - Drag yt-dlp-MAX to the Applications folder
   - The app will be copied to your Applications

2. FIRST LAUNCH (IMPORTANT!):
   ⚠️ DO NOT double-click the app on first launch!
   
   Instead:
   a) Open Finder → Applications
   b) Find yt-dlp-MAX
   c) Right-click on yt-dlp-MAX
   d) Select "Open" from the menu
   e) Click "Open" in the security dialog
   
   After the first launch, you can open it normally.

3. INSTALL DEPENDENCIES:
   Open Terminal and run:
   
   # Install Homebrew (if not installed):
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install required tools:
   brew install yt-dlp ffmpeg

4. TROUBLESHOOTING:

   If you see "App is damaged and can't be opened":
   - Open Terminal
   - Run: xattr -cr /Applications/yt-dlp-MAX.app
   - Try opening again with right-click → Open

   If downloads fail:
   - Make sure yt-dlp is installed: which yt-dlp
   - Make sure ffmpeg is installed: which ffmpeg
   - Check Preferences → Download location is valid

5. FEATURES:
   ✓ Auto-paste URLs from clipboard
   ✓ Download queue with concurrent downloads
   ✓ Custom download locations
   ✓ Quality selection
   ✓ Single-pane mode
   ✓ Enhanced context menus
   ✓ Debug console

Enjoy yt-dlp-MAX!
═══════════════════════════════════════════════════════════
EOF

# Step 4: Create DMG
echo -e "${YELLOW}Step 4: Creating DMG...${NC}"
DMG_NAME="${APP_NAME}-${VERSION}-Portable"

# Remove old DMG if exists
rm -f "$DMG_PATH/${DMG_NAME}.dmg"

# Create DMG with nice settings
hdiutil create -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH/${DMG_NAME}.dmg"

# Clean up
rm -rf "$TEMP_DIR"

# Step 5: Create a simple ZIP alternative
echo -e "${YELLOW}Step 5: Creating ZIP alternative...${NC}"
cd "$HOME/Desktop"
zip -r "${APP_NAME}-${VERSION}-Portable.zip" "${APP_NAME}.app"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SUCCESS! Created portable distributions:${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "📦 DMG: $DMG_PATH/${DMG_NAME}.dmg"
echo "📦 ZIP: $HOME/Desktop/${APP_NAME}-${VERSION}-Portable.zip"
echo ""
echo -e "${YELLOW}To share with your friend:${NC}"
echo "1. Send either the DMG or ZIP file"
echo "2. Include these instructions:"
echo "   - Right-click → Open on first launch (IMPORTANT!)"
echo "   - Install: brew install yt-dlp ffmpeg"
echo "   - If 'damaged' error: xattr -cr /Applications/yt-dlp-MAX.app"
echo ""
echo "The app is ready for distribution! 🎉"
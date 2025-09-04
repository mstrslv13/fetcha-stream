#!/bin/bash

# yt-dlp-MAX Distribution Packager
# This script helps package the app for distribution to friends

set -e

echo "🚀 yt-dlp-MAX Distribution Packager"
echo "===================================="
echo ""

# Configuration
APP_NAME="yt-dlp-MAX"
PROJECT_DIR="/Users/mstrslv/devspace/yt-dlp-MAX"
BUILD_DIR="${PROJECT_DIR}/build"
DIST_DIR="${PROJECT_DIR}/dist"
DMG_NAME="${APP_NAME}-v1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Creating directories...${NC}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

echo -e "${YELLOW}Step 2: Building Release version...${NC}"
echo "Please follow these steps in Xcode:"
echo "1. Open Xcode (if not already open)"
echo "2. Select 'Product' menu → 'Scheme' → 'Edit Scheme...'"
echo "3. In 'Run' section, change 'Build Configuration' to 'Release'"
echo "4. Close the scheme editor"
echo "5. Select 'Product' menu → 'Build' (or press ⌘+B)"
echo "6. Once build succeeds, select 'Product' menu → 'Archive'"
echo ""
read -p "Press Enter when you've completed the Archive build in Xcode..."

echo -e "${YELLOW}Step 3: Exporting the app...${NC}"
echo "In the Organizer window that opened:"
echo "1. Select your archive"
echo "2. Click 'Distribute App'"
echo "3. Choose 'Copy App' (for direct distribution)"
echo "4. Click 'Next' and then 'Export'"
echo "5. Choose a location (Desktop is fine)"
echo ""
read -p "Press Enter when you've exported the app..."

echo -e "${YELLOW}Step 4: Locating the exported app...${NC}"
read -p "Enter the path to the exported .app (or drag it here): " APP_PATH

# Remove quotes if dragged from Finder
APP_PATH="${APP_PATH//\'/}"
APP_PATH="${APP_PATH//\"/}"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App not found at ${APP_PATH}${NC}"
    exit 1
fi

echo -e "${GREEN}Found app at: ${APP_PATH}${NC}"

echo -e "${YELLOW}Step 5: Creating DMG installer...${NC}"

# Copy app to dist folder
cp -R "${APP_PATH}" "${DIST_DIR}/"

# Create a temporary directory for DMG contents
DMG_TEMP="${DIST_DIR}/dmg_temp"
mkdir -p "${DMG_TEMP}"

# Copy app to DMG temp
cp -R "${APP_PATH}" "${DMG_TEMP}/"

# Create Applications shortcut
ln -s /Applications "${DMG_TEMP}/Applications"

# Create README file
cat > "${DMG_TEMP}/README.txt" << EOF
yt-dlp-MAX Installation Instructions
=====================================

1. Drag yt-dlp-MAX to the Applications folder
2. On first launch, you may need to right-click and select "Open" 
   to bypass Gatekeeper (since the app isn't notarized)
3. Make sure you have yt-dlp and ffmpeg installed:
   - Install Homebrew from https://brew.sh
   - Run: brew install yt-dlp ffmpeg

Enjoy downloading videos with a beautiful GUI!

Note: This app requires macOS 12.0 or later.
EOF

# Create DMG
echo "Creating DMG installer..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov \
    -format UDZO \
    "${DIST_DIR}/${DMG_NAME}.dmg"

# Clean up
rm -rf "${DMG_TEMP}"

echo -e "${GREEN}✅ Success! Distribution package created:${NC}"
echo -e "${GREEN}   ${DIST_DIR}/${DMG_NAME}.dmg${NC}"
echo ""
echo -e "${YELLOW}To share with your friend:${NC}"
echo "1. Send them the DMG file: ${DMG_NAME}.dmg"
echo "2. Tell them to:"
echo "   - Double-click the DMG to mount it"
echo "   - Drag yt-dlp-MAX to Applications"
echo "   - Right-click and select 'Open' on first launch"
echo "   - Install yt-dlp and ffmpeg via Homebrew"
echo ""
echo -e "${GREEN}Distribution package ready! 🎉${NC}"
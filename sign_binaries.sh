#!/bin/bash

# Sign bundled binaries with Hardened Runtime for distribution
# This is required for App Store Connect / TestFlight distribution

set -e

echo "🔐 Signing Bundled Binaries with Hardened Runtime"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RESOURCES_DIR="./yt-dlp-MAX/Resources/bin"

# Check if binaries exist
if [ ! -d "$RESOURCES_DIR" ]; then
    echo -e "${RED}Error: Resources/bin directory not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Getting your signing identity...${NC}"

# Get the development team ID from the project
TEAM_ID=$(grep -m1 'DEVELOPMENT_TEAM = ' yt-dlp-MAX.xcodeproj/project.pbxproj | cut -d' ' -f3 | tr -d ';')
echo "Development Team: $TEAM_ID"

# Find signing identity
IDENTITY=$(security find-identity -v -p codesigning | grep "$TEAM_ID" | head -1 | cut -d'"' -f2)

if [ -z "$IDENTITY" ]; then
    echo -e "${RED}Error: No signing identity found${NC}"
    echo "Available identities:"
    security find-identity -v -p codesigning
    echo ""
    echo "Please specify your identity:"
    read -p "Enter signing identity (e.g., 'Apple Development: Your Name'): " IDENTITY
fi

echo "Using identity: $IDENTITY"

echo -e "${YELLOW}Step 2: Signing binaries with Hardened Runtime...${NC}"

# Sign yt-dlp
if [ -f "$RESOURCES_DIR/yt-dlp" ]; then
    echo "Signing yt-dlp..."
    codesign --force --options runtime --sign "$IDENTITY" \
        --timestamp \
        --entitlements yt-dlp-MAX/yt_dlp_MAX.entitlements \
        "$RESOURCES_DIR/yt-dlp"
    echo -e "${GREEN}✓ yt-dlp signed${NC}"
else
    echo -e "${RED}✗ yt-dlp not found${NC}"
fi

# Sign ffmpeg
if [ -f "$RESOURCES_DIR/ffmpeg" ]; then
    echo "Signing ffmpeg..."
    codesign --force --options runtime --sign "$IDENTITY" \
        --timestamp \
        --entitlements yt-dlp-MAX/yt_dlp_MAX.entitlements \
        "$RESOURCES_DIR/ffmpeg"
    echo -e "${GREEN}✓ ffmpeg signed${NC}"
else
    echo -e "${RED}✗ ffmpeg not found${NC}"
fi

# Sign ffprobe
if [ -f "$RESOURCES_DIR/ffprobe" ]; then
    echo "Signing ffprobe..."
    codesign --force --options runtime --sign "$IDENTITY" \
        --timestamp \
        --entitlements yt-dlp-MAX/yt_dlp_MAX.entitlements \
        "$RESOURCES_DIR/ffprobe"
    echo -e "${GREEN}✓ ffprobe signed${NC}"
else
    echo -e "${RED}✗ ffprobe not found${NC}"
fi

echo -e "${YELLOW}Step 3: Verifying signatures...${NC}"

# Verify signatures
echo "Verifying yt-dlp..."
codesign -dv --verbose=4 "$RESOURCES_DIR/yt-dlp" 2>&1 | grep -E "(Authority|TeamIdentifier|Signature|flags)"

echo ""
echo "Verifying ffmpeg..."
codesign -dv --verbose=4 "$RESOURCES_DIR/ffmpeg" 2>&1 | grep -E "(Authority|TeamIdentifier|Signature|flags)"

echo ""
echo "Verifying ffprobe..."
codesign -dv --verbose=4 "$RESOURCES_DIR/ffprobe" 2>&1 | grep -E "(Authority|TeamIdentifier|Signature|flags)"

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Binaries signed with Hardened Runtime!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Archive the project in Xcode"
echo "2. The signed binaries will be included in the app bundle"
echo "3. You can now upload to App Store Connect"
echo ""
echo -e "${YELLOW}Note:${NC} If you get 'resource fork, Finder information, or similar' errors,"
echo "run this command on each binary:"
echo "  xattr -cr $RESOURCES_DIR/*"
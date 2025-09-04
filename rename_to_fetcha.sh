#!/bin/bash

# Rename yt-dlp-MAX to fetcha.stream
# This script renames all project files and references

set -e

echo "🔄 Renaming yt-dlp-MAX to fetcha.stream"
echo "========================================"

OLD_NAME="yt-dlp-MAX"
NEW_NAME="fetcha.stream"
OLD_NAME_UNDERSCORE="yt_dlp_MAX"
NEW_NAME_UNDERSCORE="fetcha_stream"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Renaming directories...${NC}"

# Rename main directories
if [ -d "$OLD_NAME" ]; then
    mv "$OLD_NAME" "$NEW_NAME"
    echo "✓ Renamed $OLD_NAME → $NEW_NAME"
fi

if [ -d "${OLD_NAME}Tests" ]; then
    mv "${OLD_NAME}Tests" "${NEW_NAME}Tests"
    echo "✓ Renamed ${OLD_NAME}Tests → ${NEW_NAME}Tests"
fi

if [ -d "${OLD_NAME}UITests" ]; then
    mv "${OLD_NAME}UITests" "${NEW_NAME}UITests"
    echo "✓ Renamed ${OLD_NAME}UITests → ${NEW_NAME}UITests"
fi

echo -e "${YELLOW}Step 2: Renaming project files...${NC}"

# Rename xcodeproj
if [ -d "${OLD_NAME}.xcodeproj" ]; then
    mv "${OLD_NAME}.xcodeproj" "${NEW_NAME}.xcodeproj"
    echo "✓ Renamed ${OLD_NAME}.xcodeproj → ${NEW_NAME}.xcodeproj"
fi

# Rename test plan
if [ -f "${OLD_NAME}.xctestplan" ]; then
    mv "${OLD_NAME}.xctestplan" "${NEW_NAME}.xctestplan"
    echo "✓ Renamed test plan"
fi

echo -e "${YELLOW}Step 3: Updating file contents...${NC}"

# Update project.pbxproj
sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "${NEW_NAME}.xcodeproj/project.pbxproj"
sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" "${NEW_NAME}.xcodeproj/project.pbxproj"
echo "✓ Updated project.pbxproj"

# Update workspace files
if [ -f "${NEW_NAME}.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "${NEW_NAME}.xcodeproj/project.xcworkspace/contents.xcworkspacedata"
    echo "✓ Updated workspace data"
fi

# Update schemes
if [ -d "${NEW_NAME}.xcodeproj/xcshareddata/xcschemes" ]; then
    for scheme in "${NEW_NAME}.xcodeproj/xcshareddata/xcschemes"/*.xcscheme; do
        if [ -f "$scheme" ]; then
            sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "$scheme"
            # Rename the scheme file itself
            new_scheme="${scheme/${OLD_NAME}/${NEW_NAME}}"
            if [ "$scheme" != "$new_scheme" ]; then
                mv "$scheme" "$new_scheme"
            fi
        fi
    done
    echo "✓ Updated schemes"
fi

# Update test plan
if [ -f "${NEW_NAME}.xctestplan" ]; then
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "${NEW_NAME}.xctestplan"
    echo "✓ Updated test plan"
fi

echo -e "${YELLOW}Step 4: Updating Swift files...${NC}"

# Update main app file
if [ -f "${NEW_NAME}/${OLD_NAME_UNDERSCORE}App.swift" ]; then
    mv "${NEW_NAME}/${OLD_NAME_UNDERSCORE}App.swift" "${NEW_NAME}/${NEW_NAME_UNDERSCORE}App.swift"
    sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" "${NEW_NAME}/${NEW_NAME_UNDERSCORE}App.swift"
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "${NEW_NAME}/${NEW_NAME_UNDERSCORE}App.swift"
    echo "✓ Renamed and updated App.swift"
fi

# Update entitlements
if [ -f "${NEW_NAME}/${OLD_NAME_UNDERSCORE}.entitlements" ]; then
    mv "${NEW_NAME}/${OLD_NAME_UNDERSCORE}.entitlements" "${NEW_NAME}/${NEW_NAME_UNDERSCORE}.entitlements"
    echo "✓ Renamed entitlements file"
fi

# Update all Swift files for references
find "${NEW_NAME}" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;
find "${NEW_NAME}Tests" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;
find "${NEW_NAME}UITests" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;

# Update underscore references
find "${NEW_NAME}" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" {} \;
find "${NEW_NAME}Tests" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" {} \;
find "${NEW_NAME}UITests" -name "*.swift" -type f -exec sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" {} \;

echo "✓ Updated all Swift files"

echo -e "${YELLOW}Step 5: Updating test files...${NC}"

# Rename test files
if [ -f "${NEW_NAME}Tests/${OLD_NAME_UNDERSCORE}Tests.swift" ]; then
    mv "${NEW_NAME}Tests/${OLD_NAME_UNDERSCORE}Tests.swift" "${NEW_NAME}Tests/${NEW_NAME_UNDERSCORE}Tests.swift"
    echo "✓ Renamed main test file"
fi

if [ -f "${NEW_NAME}UITests/${OLD_NAME_UNDERSCORE}UITests.swift" ]; then
    mv "${NEW_NAME}UITests/${OLD_NAME_UNDERSCORE}UITests.swift" "${NEW_NAME}UITests/${NEW_NAME_UNDERSCORE}UITests.swift"
    echo "✓ Renamed UI test file"
fi

if [ -f "${NEW_NAME}UITests/${OLD_NAME_UNDERSCORE}UITestsLaunchTests.swift" ]; then
    mv "${NEW_NAME}UITests/${OLD_NAME_UNDERSCORE}UITestsLaunchTests.swift" "${NEW_NAME}UITests/${NEW_NAME_UNDERSCORE}UITestsLaunchTests.swift"
    echo "✓ Renamed UI launch test file"
fi

echo -e "${YELLOW}Step 6: Updating documentation...${NC}"

# Update README
if [ -f "README.md" ]; then
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" README.md
    echo "✓ Updated README.md"
fi

# Update CLAUDE.md
if [ -f "CLAUDE.md" ]; then
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" CLAUDE.md
    echo "✓ Updated CLAUDE.md"
fi

# Update all markdown files
find . -name "*.md" -type f -exec sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" {} \;
echo "✓ Updated all markdown files"

echo -e "${YELLOW}Step 7: Updating shell scripts...${NC}"

# Update all shell scripts
for script in *.sh; do
    if [ -f "$script" ]; then
        sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "$script"
        sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" "$script"
    fi
done
echo "✓ Updated shell scripts"

# Update Python scripts
for script in *.py; do
    if [ -f "$script" ]; then
        sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "$script"
        sed -i '' "s/${OLD_NAME_UNDERSCORE}/${NEW_NAME_UNDERSCORE}/g" "$script"
    fi
done
echo "✓ Updated Python scripts"

echo -e "${YELLOW}Step 8: Final cleanup...${NC}"

# Update the app display name in Info.plist references
find "${NEW_NAME}" -name "*.swift" -type f -exec sed -i '' 's/"yt-dlp-MAX"/"fetcha.stream"/g' {} \;
echo "✓ Updated display names"

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Successfully renamed to fetcha.stream!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
echo "📝 Summary of changes:"
echo "   • All directories renamed"
echo "   • Xcode project renamed"
echo "   • All file references updated"
echo "   • Documentation updated"
echo "   • Scripts updated"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the renamed project:"
echo "   open ${NEW_NAME}.xcodeproj"
echo ""
echo "2. In Xcode, verify:"
echo "   • Build Settings → Product Name = fetcha.stream"
echo "   • Target names are correct"
echo "   • Schemes are working"
echo ""
echo "3. Do a test build to ensure everything works"
echo ""
echo "4. Commit the changes:"
echo "   git add ."
echo '   git commit -m "Renamed project to fetcha.stream"'
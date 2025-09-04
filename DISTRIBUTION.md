# 📦 How to Package yt-dlp-MAX for Your Friend

## Quick Method (For Immediate Sharing)

### Option 1: Direct App Transfer (Easiest)
1. **In Xcode:**
   - Open the project in Xcode
   - Select **Product → Build** (⌘+B)
   - Select **Product → Show Build Folder in Finder**
   - Navigate to `Products/Debug` or `Products/Release`
   - Find `yt-dlp-MAX.app`

2. **Prepare for sharing:**
   - Right-click `yt-dlp-MAX.app` → **Compress**
   - This creates `yt-dlp-MAX.app.zip`
   - Send this zip file to your friend

3. **Your friend needs to:**
   - Unzip the file
   - Move `yt-dlp-MAX.app` to `/Applications`
   - **IMPORTANT**: First launch requires right-click → Open (to bypass Gatekeeper)
   - Install dependencies: `brew install yt-dlp ffmpeg`

### Option 2: Create a DMG (More Professional)

Run this command in Terminal:
```bash
cd /Users/mstrslv/devspace/yt-dlp-MAX
./package_app.sh
```

## Manual Build & Archive Method (Most Professional)

### Step 1: Build for Release
1. Open `yt-dlp-MAX.xcodeproj` in Xcode
2. Select the scheme dropdown (next to the stop button) → **Edit Scheme...**
3. Under **Run** → **Info** → Set **Build Configuration** to **Release**
4. Close scheme editor

### Step 2: Archive the App
1. Select **Product** → **Archive**
2. Wait for build to complete
3. Organizer window opens automatically

### Step 3: Export for Distribution
1. In Organizer, select your archive
2. Click **Distribute App**
3. Choose **Copy App** (since we're not using App Store)
4. Click **Next** → **Export**
5. Save to Desktop

### Step 4: Create DMG (Optional but Recommended)
```bash
# Create a folder for DMG contents
mkdir -p ~/Desktop/yt-dlp-MAX-Install
cp -R ~/Desktop/yt-dlp-MAX.app ~/Desktop/yt-dlp-MAX-Install/
ln -s /Applications ~/Desktop/yt-dlp-MAX-Install/Applications

# Create DMG
hdiutil create -volname "yt-dlp-MAX" \
    -srcfolder ~/Desktop/yt-dlp-MAX-Install \
    -ov -format UDZO \
    ~/Desktop/yt-dlp-MAX.dmg

# Clean up
rm -rf ~/Desktop/yt-dlp-MAX-Install
```

## What Your Friend Needs

### System Requirements:
- macOS 12.0 (Monterey) or later
- About 50MB free disk space

### Dependencies to Install:
```bash
# Install Homebrew first (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then install required tools
brew install yt-dlp ffmpeg
```

### First Launch Instructions:
1. **IMPORTANT**: Don't double-click the app on first launch
2. Instead: Right-click → Open → Click "Open" in the security dialog
3. This bypasses macOS Gatekeeper for unsigned apps
4. Subsequent launches can be done normally

## Troubleshooting

### "App is damaged and can't be opened"
This happens with unsigned apps. Fix:
```bash
xattr -cr /Applications/yt-dlp-MAX.app
```

### "yt-dlp not found"
Make sure yt-dlp is installed:
```bash
brew install yt-dlp
which yt-dlp  # Should show path
```

### "ffmpeg not found" 
Make sure ffmpeg is installed:
```bash
brew install ffmpeg
which ffmpeg  # Should show path
```

## Making it Even Better

To avoid security warnings, you could:
1. **Code sign** the app with an Apple Developer account ($99/year)
2. **Notarize** the app with Apple (requires developer account)
3. Create a **Homebrew Cask** for easy installation

For now, the direct transfer method works perfectly for sharing with friends!

## Quick Checklist for Sharing

- [ ] Build the app in Release mode
- [ ] Create zip or DMG
- [ ] Include these instructions:
  - Right-click → Open on first launch
  - Install: `brew install yt-dlp ffmpeg`
  - Download location: `~/Downloads`
- [ ] Test on your machine first
- [ ] Send to friend with instructions

Enjoy sharing yt-dlp-MAX! 🚀
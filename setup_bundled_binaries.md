# Adding Bundled Binaries to Xcode Project

## Steps to Bundle yt-dlp and ffmpeg with the App

### 1. Add Resources Folder to Xcode

1. **Open your project in Xcode**

2. **Right-click on the "yt-dlp-MAX" folder** (the one with your source files)

3. Select **"Add Files to yt-dlp-MAX..."**

4. Navigate to `/Users/mstrslv/devspace/yt-dlp-MAX/yt-dlp-MAX/`

5. Select the **"Resources"** folder

6. Make sure these options are checked:
   - ✅ Copy items if needed (should be unchecked since it's already in the project folder)
   - ✅ Create folder references (NOT groups)
   - ✅ Add to targets: yt-dlp-MAX

7. Click **Add**

### 2. Verify the Resources are Set to Copy

1. Select your **project** in the navigator

2. Select the **"yt-dlp-MAX" target**

3. Go to **"Build Phases"** tab

4. Expand **"Copy Bundle Resources"**

5. You should see the Resources folder there. If not:
   - Click the **+** button
   - Add the Resources folder

### 3. Update Build Phase to Preserve Executable Permissions

1. Still in **"Build Phases"**

2. Click **+** → **"New Run Script Phase"**

3. Name it: **"Fix Binary Permissions"**

4. Add this script:
```bash
# Fix permissions for bundled binaries
chmod +x "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/yt-dlp"
chmod +x "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/ffmpeg"
chmod +x "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/bin/ffprobe"
```

5. Drag this phase to run **after** "Copy Bundle Resources"

### 4. Test the Bundle

Build and run the app. In the debug console, you should see:
- "Using bundled yt-dlp"
- "Using bundled ffmpeg"

## Binary Sizes

Current bundle adds approximately:
- yt-dlp: 34 MB (standalone binary)
- ffmpeg: 412 KB
- ffprobe: 344 KB
- **Total: ~35 MB added to app size**

## Benefits

✅ **No dependencies** - Users don't need Homebrew or any installations
✅ **Consistent versions** - Everyone uses the same yt-dlp/ffmpeg versions
✅ **Works immediately** - Just drag to Applications and run
✅ **Portable** - Can run from anywhere, even USB drives

## Alternative: Download on First Launch

If 35MB is too large, we could instead:
1. Check for bundled binaries
2. If not found, offer to download them on first launch
3. Save them to Application Support folder

But bundling is simpler and more reliable!
# Setup Instructions for yt-dlp-MAX Queue System

## Files to Add to Xcode Project

The following files need to be added to your Xcode project:

### 1. In Xcode, add these files:

**Services Group:**
- `yt-dlp-MAX/Services/DownloadQueue.swift` - The main queue management service

**Views Group:**
- `yt-dlp-MAX/Views/QueueView.swift` - The queue display view
- `yt-dlp-MAX/Views/QueueSettingsView.swift` - Settings for queue configuration

### 2. How to Add Files in Xcode:

1. Open `yt-dlp-MAX.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar):
   - Right-click on the `yt-dlp-MAX` folder
   - Select "Add Files to 'yt-dlp-MAX'..."
   - Navigate to the `yt-dlp-MAX` folder in the file dialog
   - Select the `Services` and `Views` folders
   - Make sure:
     - ✅ "Create groups" is selected
     - ✅ Target "yt-dlp-MAX" is checked
     - ❌ "Copy items if needed" is UNCHECKED (files are already in place)
   - Click "Add"

### 3. Remove Old Files:

If you see `DownloadQueueView.swift` in the project (it will show in red as missing):
- Right-click on it
- Select "Delete"
- Choose "Remove Reference"

### 4. Build and Run:

1. Press `Cmd+B` to build the project
2. Fix any remaining import issues if they appear
3. Press `Cmd+R` to run the application

## Features Now Available:

- **Download Queue**: Add multiple videos to download queue
- **Parallel Downloads**: Configure 1-10 simultaneous downloads
- **Save Location**: Choose where to save videos
- **Consistent Format**: Option to use same format for all videos
- **Queue Controls**: Pause, resume, remove items from queue
- **Settings Panel**: Access via gear icon in queue view

## Testing the Queue:

1. Enter a video URL
2. Click "Fetch Video Info"
3. Select a format (or use consistent format in settings)
4. Click "Add to Queue"
5. Add more videos
6. Click "View Queue" to see and manage downloads
7. Use the gear icon in queue view to adjust settings
# Binary Detection Issues - QA Analysis Report

## Executive Summary

The yt-dlp-MAX application has **critical binary detection failures** preventing it from locating and executing yt-dlp and ffmpeg binaries. The root causes include:

1. **Missing manual yt-dlp path configuration** (unlike ffmpeg which has it)
2. **Sandbox entitlement restrictions** blocking binary execution
3. **No error recovery mechanisms** when auto-detection fails
4. **Incomplete path validation** before execution attempts

## Priority 1: Root Cause Analysis

### Issue 1: "Operation not permitted" for yt-dlp

**Location**: `/Users/mstrslv/devspace/yt-dlp-MAX 2/yt-dlp-MAX/Services/YTDLPService.swift`

**Problem**: The app shows "Operation not permitted" when trying to execute yt-dlp at `/opt/homebrew/bin/yt-dlp`

**Root Cause**:
- The sandbox entitlements file has hardcoded paths that may not match actual binary locations
- The `com.apple.security.temporary-exception.files.absolute-path.read-execute` entitlement only allows specific paths
- If yt-dlp is installed elsewhere, sandbox blocks execution

**Evidence**:
```xml
<!-- From yt-dlp-MAX.entitlements lines 45-54 -->
<key>com.apple.security.temporary-exception.files.absolute-path.read-execute</key>
<array>
    <string>/opt/homebrew/bin/yt-dlp</string>
    <string>/usr/local/bin/yt-dlp</string>
    <!-- Limited to these specific paths only -->
</array>
```

### Issue 2: Manual ffmpeg selection not working

**Location**: `/Users/mstrslv/devspace/yt-dlp-MAX 2/yt-dlp-MAX/Views/PreferencesView.swift` (lines 394-403)

**Problem**: The UI has a field for manual ffmpeg path, but changes don't register

**Root Cause**:
- The `@AppStorage("ffmpegPath")` is properly bound in `AppPreferences.swift`
- The UI correctly sets `preferences.ffmpegPath` 
- **However**, the `resolvedFfmpegPath` computed property (lines 84-118) has a logic issue:
  - It only uses manual path if the file exists
  - If the file doesn't exist, it falls back to auto-detection
  - No user feedback when manual path is invalid

### Issue 3: No manual yt-dlp path option

**Location**: Missing functionality

**Problem**: Unlike ffmpeg, there's no UI option to manually specify yt-dlp path

**Root Cause**:
- `AppPreferences.swift` has `ffmpegPath` property but no `ytdlpPath`
- `PreferencesView.swift` has ffmpeg path UI but nothing for yt-dlp
- `YTDLPService.swift` only uses auto-detection with no manual override

## Priority 2: Code Analysis Findings

### Binary Detection Logic

**File**: `YTDLPService.swift`

1. **findYTDLP() method** (lines 96-168):
   - Searches predefined paths
   - Falls back to `which` command
   - **Issue**: No manual path override option

2. **getYTDLPPath() method** (lines 177-213):
   - Uses caching for performance
   - Validates file exists and is executable
   - **Issue**: No way to specify custom path

3. **findFFmpeg() method** (lines 30-91):
   - Similar to findYTDLP
   - **Issue**: Doesn't check manual path first

### Path Storage

**File**: `AppPreferences.swift`

1. **Missing property**:
   ```swift
   // Has this:
   @AppStorage("ffmpegPath") var ffmpegPath: String = ""
   
   // Missing this:
   @AppStorage("ytdlpPath") var ytdlpPath: String = ""
   ```

2. **resolvedFfmpegPath issues** (lines 84-118):
   - Falls back silently when manual path invalid
   - Uses synchronous Process execution (deprecated pattern)

### Sandbox Restrictions

**Files**: `yt-dlp-MAX.entitlements`, `yt_dlp_MAX.entitlements`

1. **Hardcoded paths**: Only allows execution from specific locations
2. **No dynamic path support**: Can't add new paths at runtime
3. **Inheritance issues**: Child processes may not inherit permissions

## Priority 3: Test Coverage

### Created Test Suite: `BinaryDetectionTests.swift`

**Coverage Areas**:
1. ✅ Sandbox restriction detection
2. ✅ Manual path validation
3. ✅ Binary existence checks
4. ✅ Permission verification
5. ✅ Error message quality
6. ✅ Cache validation
7. ✅ Performance metrics

**Test Results Expected**:
- `testYTDLPDetectionInSandboxedEnvironment`: Will fail if sandbox blocks execution
- `testFFmpegDetectionAndManualPath`: Will fail if manual path not respected  
- `testMissingManualYTDLPPathOption`: Will fail (confirms missing feature)
- `testEntitlementPaths`: Will show which paths are accessible

## Priority 4: Recommended Fixes

### Fix 1: Add Manual yt-dlp Path Support

**AppPreferences.swift** - Add:
```swift
@AppStorage("ytdlpPath") var ytdlpPath: String = ""

var resolvedYtdlpPath: String {
    // Check manual path first
    if !ytdlpPath.isEmpty {
        let expanded = NSString(string: ytdlpPath).expandingTildeInPath
        if FileManager.default.isExecutableFile(atPath: expanded) {
            return expanded
        }
    }
    // Fall back to auto-detection
    return "" // Let YTDLPService handle auto-detection
}
```

**PreferencesView.swift** - Add UI similar to ffmpeg:
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("yt-dlp Configuration")
        .font(.headline)
    
    HStack {
        Text("yt-dlp path:")
        TextField("Auto-detect", text: $preferences.ytdlpPath)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 300)
        Button("Browse...") {
            showingYtdlpPicker = true
        }
    }
}
```

### Fix 2: Update YTDLPService to Check Manual Path

**YTDLPService.swift** - Modify `findYTDLP()`:
```swift
private func findYTDLP() async -> String? {
    // FIRST: Check manual path from preferences
    let manualPath = preferences.resolvedYtdlpPath
    if !manualPath.isEmpty && FileManager.default.isExecutableFile(atPath: manualPath) {
        return manualPath
    }
    
    // SECOND: Check bundled version
    // ... existing bundled check code ...
    
    // THIRD: Check common paths
    // ... existing path checking code ...
}
```

### Fix 3: Improve Error Messages

**YTDLPService.swift** - Better error reporting:
```swift
enum YTDLPError: LocalizedError {
    case ytdlpNotFound
    case sandboxRestriction(String)
    case invalidManualPath(String)
    
    var errorDescription: String? {
        switch self {
        case .sandboxRestriction(let path):
            return "Cannot execute yt-dlp at \(path) due to sandbox restrictions. Please install yt-dlp at /opt/homebrew/bin/ or /usr/local/bin/"
        case .invalidManualPath(let path):
            return "Manual path '\(path)' is not valid or not executable"
        // ... other cases
        }
    }
}
```

### Fix 4: Add Path Validation UI Feedback

**PreferencesView.swift** - Add validation:
```swift
func validateBinaryPath(_ path: String, isFfmpeg: Bool) -> (valid: Bool, message: String) {
    let expanded = NSString(string: path).expandingTildeInPath
    
    if !FileManager.default.fileExists(atPath: expanded) {
        return (false, "File not found")
    }
    
    if !FileManager.default.isExecutableFile(atPath: expanded) {
        return (false, "File not executable")
    }
    
    // Validate it's the right binary
    let process = Process()
    process.executableURL = URL(fileURLWithPath: expanded)
    process.arguments = ["--version"]
    // ... run and check output ...
    
    return (true, "Valid")
}
```

### Fix 5: Consider Bundling Binaries

**Long-term solution**: Bundle yt-dlp and ffmpeg with the app
- Eliminates sandbox issues
- Ensures consistent versions
- No dependency on user installation
- Requires updating binaries with app updates

## Testing Recommendations

1. **Run test suite**: `swift test --filter BinaryDetectionTests`
2. **Manual testing**:
   - Test with yt-dlp in non-standard location
   - Test with missing binaries
   - Test with invalid permissions
   - Test manual path entry and validation

3. **Regression testing**:
   - Ensure fixes don't break existing auto-detection
   - Verify sandbox still allows approved paths
   - Check performance isn't degraded

## Risk Assessment

**High Risk**:
- Sandbox restrictions blocking all execution
- Users unable to use app without specific installation paths

**Medium Risk**:
- Manual path configuration complexity
- Performance impact from repeated detection attempts

**Low Risk**:
- UI changes for manual path entry
- Error message improvements

## Conclusion

The binary detection issues stem from:
1. **Incomplete implementation** - Missing manual yt-dlp path option
2. **Sandbox restrictions** - Hardcoded entitlement paths
3. **Poor error handling** - Unclear error messages
4. **No fallback mechanisms** - Auto-detection only

**Immediate actions required**:
1. Add manual yt-dlp path support (like ffmpeg has)
2. Improve error messages to guide users
3. Validate paths before attempting execution
4. Consider bundling binaries for future releases

The test suite in `BinaryDetectionTests.swift` provides comprehensive coverage to verify fixes work correctly and catch regressions.
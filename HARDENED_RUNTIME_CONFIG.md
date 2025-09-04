# Hardened Runtime Configuration for yt-dlp-MAX (Fetcha)

## Overview
This document describes the hardened runtime configuration for yt-dlp-MAX, which is required for notarization and distribution on macOS 10.15 (Catalina) and later.

## Configuration Status: ✅ ENABLED

### Project Settings
- **ENABLE_HARDENED_RUNTIME**: YES (set in Debug and Release configurations)
- **CODE_SIGN_ENTITLEMENTS**: Points to `yt-dlp-MAX/yt_dlp_MAX.entitlements`
- **Development Team**: V34B6J7FGG

## Entitlements Configuration

### Sandbox Entitlements
These entitlements define the app's sandbox permissions:

1. **`com.apple.security.app-sandbox`**: `true`
   - Enables the app sandbox for security

2. **`com.apple.security.network.client`**: `true`
   - Allows network access for downloading videos

3. **`com.apple.security.files.downloads.read-write`**: `true`
   - Permits read/write access to the Downloads folder

4. **`com.apple.security.files.user-selected.read-write`**: `true`
   - Allows access to user-selected file locations

### Hardened Runtime Exceptions
These exceptions are required for the app to function with hardened runtime:

1. **`com.apple.security.cs.allow-unsigned-executable-memory`**: `true`
   - Required for Python/yt-dlp execution
   - Allows JIT compilation and dynamic code generation

2. **`com.apple.security.cs.allow-dyld-environment-variables`**: `true`
   - Enables passing environment variables to subprocesses
   - Needed for configuring Python and yt-dlp behavior

3. **`com.apple.security.cs.disable-library-validation`**: `true`
   - Allows loading of third-party libraries
   - Required for executing external binaries (yt-dlp, ffmpeg)

4. **`com.apple.security.cs.allow-jit`**: `true`
   - Permits just-in-time compilation
   - Essential for Python interpreter operation

5. **`com.apple.security.inherit`**: `true`
   - Child processes inherit the parent's entitlements
   - Necessary for subprocess execution

### Temporary Exceptions
These paths are temporarily allowed for read-execute access:
- `/opt/homebrew/bin/yt-dlp` (Apple Silicon Homebrew)
- `/usr/local/bin/yt-dlp` (Intel Homebrew)
- `/opt/homebrew/bin/ffmpeg` (Apple Silicon Homebrew)
- `/usr/local/bin/ffmpeg` (Intel Homebrew)
- `/usr/bin/python3` (System Python)
- `/usr/local/bin/python3` (Intel Homebrew Python)
- `/opt/homebrew/bin/python3` (Apple Silicon Homebrew Python)

**Note**: These exceptions should be removed when yt-dlp and ffmpeg are bundled within the app.

## Verification Steps

### 1. Check Project Configuration
```bash
grep "ENABLE_HARDENED_RUNTIME" yt-dlp-MAX.xcodeproj/project.pbxproj
# Should show: ENABLE_HARDENED_RUNTIME = YES
```

### 2. Verify Built App
```bash
# Check if hardened runtime flag is present
codesign -dvv "build/Release/yt-dlp-MAX.app" 2>&1 | grep flags
# Should show: flags=0x10000(runtime)

# Display embedded entitlements
codesign -d --entitlements - "build/Release/yt-dlp-MAX.app"
```

### 3. Run Verification Script
```bash
./verify_hardened_runtime.sh
```

## Notarization Process

### Prerequisites
1. **Developer ID Certificate**: Required for code signing
2. **Apple Developer Account**: Needed for notarization service
3. **App-Specific Password**: Generate at https://appleid.apple.com

### Steps
1. **Build and Archive**:
   ```bash
   ./prepare_for_notarization.sh
   ```

2. **Submit for Notarization**:
   ```bash
   xcrun notarytool submit build/yt-dlp-MAX.zip \
     --apple-id "your@email.com" \
     --team-id "V34B6J7FGG" \
     --password "app-specific-password" \
     --wait
   ```

3. **Staple the Ticket**:
   ```bash
   xcrun stapler staple "build/export/yt-dlp-MAX.app"
   ```

4. **Verify**:
   ```bash
   spctl -a -vvv -t install "build/export/yt-dlp-MAX.app"
   # Should show: accepted, source=Notarized Developer ID
   ```

## Security Considerations

### Current Security Posture
- ✅ App Sandbox enabled
- ✅ Hardened Runtime enabled
- ✅ Code signing configured
- ⚠️ Several runtime exceptions required for functionality

### Future Improvements
1. **Bundle Dependencies**: Include yt-dlp and ffmpeg in the app bundle to remove file system exceptions
2. **Reduce Runtime Exceptions**: Minimize the number of hardened runtime exceptions
3. **Library Validation**: Re-enable library validation after bundling dependencies

## Troubleshooting

### Common Issues

1. **"App is damaged" error**:
   - Ensure the app is properly notarized
   - Check that hardened runtime is enabled
   - Verify code signature: `codesign --verify --deep --strict --verbose=2 yt-dlp-MAX.app`

2. **Notarization fails**:
   - Check that all runtime exceptions are properly declared
   - Ensure no unsigned code or libraries are included
   - Review notarization log: `xcrun notarytool log <submission-id> --apple-id "your@email.com"`

3. **Subprocess execution fails**:
   - Verify `com.apple.security.inherit` is enabled
   - Check that executable paths are in the temporary exceptions
   - Ensure `com.apple.security.cs.disable-library-validation` is set

## References
- [Apple: Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Apple: Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Apple: Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)

## Change Log
- **2025-09-03**: Initial hardened runtime configuration implemented
  - Added all necessary runtime exceptions
  - Configured entitlements for sandbox and hardened runtime
  - Created verification and preparation scripts
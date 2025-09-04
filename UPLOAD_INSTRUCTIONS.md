# Repository Upload Instructions

Your project is now ready to upload to GitHub and GitLab. Follow these instructions:

## 📊 Current Git Status
- Repository initialized ✅
- All files committed ✅  
- .gitignore configured ✅
- README and LICENSE added ✅

## 🐙 GitHub Upload

### 1. Create a new repository on GitHub
1. Go to https://github.com/new
2. Repository name: `fetcha-stream` (or `yt-dlp-MAX`)
3. Description: "Modern macOS video downloader with browser cookie support"
4. Set to Public or Private as desired
5. DO NOT initialize with README, .gitignore, or license (we already have them)
6. Click "Create repository"

### 2. Push to GitHub
```bash
cd /Users/mstrslv/devspace/yt-dlp-MAX

# Add GitHub as remote (replace YOUR_USERNAME with your GitHub username)
git remote add github https://github.com/YOUR_USERNAME/fetcha-stream.git

# Push to GitHub
git push -u github master
```

### 3. If using SSH (recommended):
```bash
# Add GitHub SSH remote instead
git remote add github git@github.com:YOUR_USERNAME/fetcha-stream.git

# Push to GitHub
git push -u github master
```

## 🦊 GitLab Upload

### 1. Create a new project on GitLab
1. Go to https://gitlab.com/projects/new
2. Project name: `fetcha-stream` (or `yt-dlp-MAX`)
3. Project slug: `fetcha-stream`
4. Visibility: Public or Private as desired
5. DO NOT initialize with README
6. Click "Create project"

### 2. Push to GitLab
```bash
cd /Users/mstrslv/devspace/yt-dlp-MAX

# Add GitLab as remote (replace YOUR_USERNAME with your GitLab username)
git remote add gitlab https://gitlab.com/YOUR_USERNAME/fetcha-stream.git

# Push to GitLab
git push -u gitlab master
```

### 3. If using SSH:
```bash
# Add GitLab SSH remote instead
git remote add gitlab git@gitlab.com:YOUR_USERNAME/fetcha-stream.git

# Push to GitLab
git push -u gitlab master
```

## 🔄 Push to Both Simultaneously

After setting up both remotes, you can push to both at once:

```bash
# View all remotes
git remote -v

# Push to both
git push github master
git push gitlab master

# Or create an alias to push to both
git remote add all https://github.com/YOUR_USERNAME/fetcha-stream.git
git remote set-url --add --push all https://gitlab.com/YOUR_USERNAME/fetcha-stream.git
git remote set-url --add --push all https://github.com/YOUR_USERNAME/fetcha-stream.git

# Then push to both with
git push all master
```

## 📝 After Upload

### On GitHub:
1. Go to Settings > Options
2. Add topics: `macos`, `swift`, `swiftui`, `yt-dlp`, `video-downloader`, `youtube-downloader`
3. Set up GitHub Actions for CI/CD (optional)
4. Create a Release with the packaged .dmg file

### On GitLab:
1. Go to Settings > General
2. Add topics/tags: `macos`, `swift`, `swiftui`, `yt-dlp`, `video-downloader`
3. Set up GitLab CI/CD (optional)
4. Create a Release with the packaged .dmg file

## 🏷️ Creating a Release

### Version Tag:
```bash
# Create a version tag
git tag -a v1.0.0 -m "Initial release - Phase 4 complete"

# Push tags to GitHub
git push github --tags

# Push tags to GitLab
git push gitlab --tags
```

### Release Notes Template:
```markdown
## fetcha.stream v1.0.0

First public release of fetcha.stream - a modern macOS video downloader.

### Features
- 🍪 Browser cookie support (Safari, Chrome, Brave, Firefox, Edge)
- 📦 Smart queue management with drag & drop
- 🎯 Multiple download locations
- 📊 Real-time progress tracking
- 🎨 Native SwiftUI interface

### Installation
1. Download `fetcha.stream_v1.0.0.dmg`
2. Open and drag to Applications
3. Right-click and select "Open" on first launch

### Requirements
- macOS 11.0 or later
- No dependencies needed (includes yt-dlp and ffmpeg)

### Known Issues
- First launch requires security approval
- Some sites may require browser cookies for private content

### SHA256 Checksums
[Include checksums from package_for_distribution.sh output]
```

## 🔐 Repository Settings Recommendations

### Branch Protection (GitHub):
1. Settings > Branches
2. Add rule for `master` branch
3. Enable "Require pull request reviews"
4. Enable "Dismiss stale pull request approvals"

### Protected Branches (GitLab):
1. Settings > Repository > Protected branches
2. Protect `master` branch
3. Set "Allowed to merge" and "Allowed to push" appropriately

## 🚀 Continuous Integration (Optional)

### GitHub Actions (.github/workflows/build.yml):
```yaml
name: Build and Test
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build
      run: xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX build
    - name: Test
      run: xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX
```

### GitLab CI (.gitlab-ci.yml):
```yaml
stages:
  - build
  - test

build:
  stage: build
  tags:
    - macos
  script:
    - xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX build

test:
  stage: test
  tags:
    - macos
  script:
    - xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX
```

## ✅ Checklist

Before uploading:
- [x] All code committed
- [x] README.md updated
- [x] LICENSE added
- [x] .gitignore configured
- [x] Sensitive data removed
- [x] Binaries included in Resources/bin
- [ ] Create GitHub repository
- [ ] Create GitLab repository
- [ ] Push code
- [ ] Create release
- [ ] Upload .dmg file

---

Good luck with your repository publication! 🚀
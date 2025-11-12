# Fetcha Stream v1.3.0 Incremental Release Plan

## Background

On September 9, 2025, the v1.3.0 UI overhaul attempt was rolled back due to critical stability issues:
- yt-dlp automatic detection was completely broken
- Onboarding repeated on every app launch
- Manual path selection wasn't persisted
- Frequent crashes and thread safety issues
- No way to exit/skip onboarding

The failed v1.3.0 attempt has been preserved in branch: `failed-1.3-attempt`

## Recovery Strategy

Instead of a single large v1.3.0 release, features will be implemented incrementally through minor version updates. Each phase will be:
1. Implemented as a separate feature
2. Thoroughly tested in isolation
3. Released as a minor version update
4. Verified in production before proceeding to the next phase

## Release Schedule

### ✅ v1.2.0 - Stable Baseline (Current)
- Reverted to last known stable state
- All core functionality working
- Clean build with no errors

### Phase 1: v1.2.1 - Onboarding & Detection
**Target Features:**
- First-launch onboarding flow
- Robust yt-dlp/ffmpeg binary detection
- Manual path selection with persistence
- Skip onboarding option
- Clear error messages for missing dependencies

**Implementation Notes:**
- Fix UserDefaults persistence for manual paths
- Add proper thread-safe singleton for YTDLPService
- Implement cache clearing for binary paths
- Add validation for manually selected binaries

### Phase 2: v1.2.2 - Theme Management
**Target Features:**
- Theme manager service with @AppStorage persistence
- System/Light/Dark mode selection
- Smooth theme transitions
- Preference UI for theme selection

**Implementation Notes:**
- Implement ThemeManager as ObservableObject
- Add theme selection to Preferences
- Test with system appearance changes

### Phase 3: v1.2.3 - Performance Monitoring
**Target Features:**
- PerformanceMonitor service
- Memory usage tracking
- Download speed analytics
- Performance metrics in DevTools

**Implementation Notes:**
- Add lightweight performance tracking
- Integrate with PersistentDebugLogger
- Display metrics without impacting performance

### Phase 4: v1.2.4 - Enhanced DevTools
**Target Features:**
- Improved log filtering (All/Error/Warn/Info/yt-dlp/ffmpeg/App)
- Dropdown menu for filter selection
- Enhanced debug console with clickable actions
- Export logs with error reporting

**Implementation Notes:**
- Replace filter pills with dropdown menu
- Add "Fetcha App" filter for app-only logs
- Implement copy/report buttons for errors

### Phase 5: v1.2.5 - Thumbnail Caching
**Target Features:**
- ThumbnailCache service with disk persistence
- Async image loading with placeholders
- Memory-efficient caching strategy
- CachedThumbnailView component

**Implementation Notes:**
- Implement NSCache with disk backing
- Add cache size limits and cleanup
- Handle failed thumbnail loads gracefully

### Phase 6: v1.2.6 - Enhanced Queue View
**Target Features:**
- Improved queue management UI
- Drag & drop reordering
- Batch operations
- Priority queue support

**Implementation Notes:**
- Build on existing QueueView
- Add gesture recognizers for reordering
- Implement batch selection mode

### Phase 7: v1.2.7 - History Panel
**Target Features:**
- Download history with search
- Filter by date/status/format
- Quick re-download actions
- History export functionality

**Implementation Notes:**
- Extend DownloadHistory service
- Add search and filter capabilities
- Implement history cleanup options

### v1.3.0 - Feature Complete
Once all phases are successfully deployed and stable:
- Merge all features
- Update version to v1.3.0
- Full regression testing
- Production release

## Testing Strategy

Each phase must pass:
1. **Unit Tests**: Test new services/models in isolation
2. **Integration Tests**: Verify interaction with existing features
3. **Manual Testing**: Full app workflow testing
4. **Build Verification**: Clean build with no warnings
5. **Performance Testing**: No degradation from baseline

## Rollback Plan

If any phase causes issues:
1. Immediately revert to previous minor version
2. Debug issue in isolated branch
3. Fix and re-test before re-releasing
4. Document lessons learned

## Success Criteria

Each phase is considered successful when:
- All tests pass
- No crash reports for 48 hours
- No performance regression
- User-reported issues addressed
- Clean integration with existing features

## Git Branch Strategy

```
main (v1.2.0) 
  ├── feature/v1.2.1-onboarding
  ├── feature/v1.2.2-themes
  ├── feature/v1.2.3-performance
  ├── feature/v1.2.4-devtools
  ├── feature/v1.2.5-thumbnails
  ├── feature/v1.2.6-queue
  └── feature/v1.2.7-history

failed-1.3-attempt (reference only - do not merge)
```

## Lessons Learned

1. **Never implement multiple major features simultaneously**
2. **Always ensure thread safety with @MainActor and proper locking**
3. **Test UserDefaults persistence thoroughly**
4. **Validate binary detection on both Intel and Apple Silicon**
5. **Implement proper error recovery and user feedback**
6. **Add skip/exit options for all modal flows**

## Timeline

- Each phase: 2-3 days development + 2 days testing
- Total estimated time to v1.3.0: 4-6 weeks
- Buffer time for issues: +2 weeks

---

*Last Updated: September 9, 2025*
*Document Version: 1.0*
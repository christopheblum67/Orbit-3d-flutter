# Orbit IPTV - TV Support Audit Report

**Date:** 2026-10-15  
**Scope:** Android TV / Fire TV / Chromecast with Google TV / TV Boxes  
**Test Device:** Galaxy S20 (mobile), TV mode forced via advanced settings

---

## Executive Summary

The app has **partial TV support** with a `TvFocus` widget system and `TvModeDetector`, but critical gaps exist for production TV deployment. The app was designed mobile-first and TV features were added incrementally without a systematic approach.

**Overall TV Readiness:** ~45% (Core navigation works, but manifest, safe areas, audio focus, and several screens lack D-pad support)

---

## Priority 1: Critical Blockers (Must Fix Before TV Release)

### 1.1 Android Manifest - Leanback Launcher Missing
**Severity:** 🔴 CRITICAL  
**File:** `android/app/src/main/AndroidManifest.xml`

**Issues:**
- `android:banner="@drawable/tv_banner"` referenced but **banner asset missing** (no `tv_banner.png` in any drawable folder)
- Missing `<category android:name="android.intent.category.LEANBACK_LAUNCHER" />` in main activity intent-filter
- `android:software.leanback` has `required="false"` - should be `true` for TV-only apps, or at minimum add leanback launcher category
- No `android:supportsPictureInPicture="true"` on application (activity has it)

**Impact:** App won't appear in Android TV launcher, no banner shown on TV home screen.

### 1.2 TV Banner Asset Missing
**Severity:** 🔴 CRITICAL  
**Location:** `android/app/src/main/res/drawable-*`

**Issues:** No 320x180 banner image exists. Required for TV launcher.

### 1.3 Safe Area / Overscan Not Handled
**Severity:** 🔴 CRITICAL  
**Files:** Multiple screens

**Issues:**
- `SafeArea` used without TV-specific minimum insets (overscan 5-10%)
- Standard `SafeArea` only handles system bars, not TV overscan
- Content (logos, text, buttons) can be cut off on TV edges

**Required:** `SafeArea(minimum: EdgeInsets.symmetric(horizontal: 48, vertical: 27))` on all screens

---

## Priority 2: High - Navigation & Focus System

### 2.1 EPG Grid - No D-pad Navigation Between Programs
**Severity:** 🟠 HIGH  
**File:** `lib/features/epg/widgets/epg_grid_2d_view.dart` (1144 lines)

**Issues:**
- Uses `GestureDetector` + `Listener` for touch/mouse only
- No `FocusNode` per channel/program
- No `FocusTraversalGroup` or `FocusTraversalOrder`
- HorizontalDragLayer handles drag but not D-pad left/right
- Vertical scroll via ListView but no focus movement between rows
- **Cannot navigate EPG grid with remote control**

### 2.2 Search Screen - TextField Not TV-Friendly
**Severity:** 🟠 HIGH  
**File:** `lib/features/search/search_screen.dart`

**Issues:**
- Uses `SearchAnchor` + `SearchBar` + `TextField` designed for touch/keyboard
- No IME options for TV (`actionSearch`, `actionDone`)
- Virtual keyboard forced on TV (no conditional `InputMethodManager`)
- Suggestions list not focusable with D-pad
- No `SearchManager` / `SearchableActivity` integration

### 2.3 Settings Screen - TabBar Not D-pad Navigable
**Severity:** 🟠 HIGH  
**File:** `lib/features/settings/unified_settings_screen.dart`

**Issues:**
- `TabBar` + `TabBarView` - tabs not individually focusable
- `DropdownButton` in DNS section not D-pad accessible
- `SettingsSwitchTile`, `SettingsNavTile` use `ListTile`/`InkWell` without `Focus` wrapper
- `SegmentedButton` in advanced settings works but no focus styling

### 2.4 Profile Edit - Partial D-pad Support
**Severity:** 🟡 MEDIUM-HIGH  
**File:** `lib/features/profile/profile_edit_screen.dart`

**Status:** Has `Focus` wrappers on chips, `onKeyEvent` handlers, "Suivant" button
**Issues:**
- `AvatarPickerGrid` not audited for D-pad
- `SegmentedButton` for profile type OK
- `TextFormField` for name - no TV IME options
- Scroll required to reach "Enregistrer" (though "Suivant" helps)

### 2.5 Home Shell - NavigationRail/NavigationBar Need Focus
**Severity:** 🟡 MEDIUM  
**File:** `lib/features/home_shell.dart`

**Issues:**
- `NavigationRail` and `NavigationBar` items not wrapped in `Focus`
- `DrawerMenuButton` only works on mobile drawer
- Wide screen rail needs `FocusTraversalGroup`

---

## Priority 3: Medium - Audio/Playback

### 3.1 MediaSession / Audio Focus
**Severity:** 🟡 MEDIUM  
**Files:** `lib/features/player/player_screen.dart`, `android/app/src/main/AndroidManifest.xml`

**Status:** Uses `video_player` with ExoPlayer internally, `BackgroundPlaybackService` for foreground service
**Issues:**
- No `MediaSessionCompat` / `MediaControllerCompat` exposed to system
- No `MediaButtonReceiver` for remote media keys (play/pause/next/prev)
- Audio focus handling relies on ExoPlayer internal (`mixWithOthers: false` helps but not sufficient)
- No `setAudioAttributes(USAGE_MEDIA, CONTENT_TYPE_MOVIE)` explicitly
- PiP works but no MediaSession for system controls

### 3.2 ExoPlayer TV Overlay
**Severity:** 🟡 MEDIUM  
**File:** `lib/features/player/player_screen.dart` (footer bars)

**Status:** Custom footer bars (`_LiveFooterBar`, `_VodFooterBar`) with D-pad key handling in `_ReadyPlayer._onKeyEvent`
**Issues:**
- Works for play/pause/seek/zapping via keys
- No integration with system media controls (notification, lock screen, headset buttons)

---

## Priority 4: Low - Polish & Performance

### 4.1 Large Heap / Memory
**Severity:** 🟢 LOW  
**File:** `android/app/src/main/AndroidManifest.xml`

**Status:** EPG buffer capped at 60 MiB, image cache bounded with `memCacheWidth`
**Issues:** No `android:largeHeap="true"` - may help on low-memory TV boxes

### 4.2 Integration Tests for TV
**Severity:** 🟢 LOW  
**Files:** `integration_test/`

**Status:** No TV-specific integration tests

---

## Screen-by-Screen D-pad Audit

| Screen | D-pad Navigation | Focus Visible | Focus Order | Notes |
|--------|-----------------|---------------|-------------|-------|
| Home | ⚠️ Partial | ⚠️ Partial | ❌ | NavigationRail/Bar not focus-wrapped |
| Live TV | ✅ Good | ✅ Good | ✅ Good | CategoriesRail + GridView with TvFocus |
| VOD | ✅ Good | ✅ Good | ✅ Good | CategoriesRail + GridView with TvFocus |
| Series | ✅ Good | ✅ Good | ✅ Good | CategoriesRail + GridView with TvFocus |
| Replay | ✅ Good | ✅ Good | ✅ Good | CategoriesRail + GridView with TvFocus |
| EPG Grid | ❌ None | ❌ None | ❌ | Custom painter, gesture-only |
| Search | ❌ None | ❌ None | ❌ | SearchAnchor/TextField not TV-ready |
| Settings | ⚠️ Partial | ⚠️ Partial | ❌ | TabBar, DropdownButton, ListTiles not focusable |
| Profile Edit | ✅ Good | ✅ Good | ✅ Good | Has Focus wrappers, "Suivant" button |
| Player | ✅ Good | ✅ Good | ✅ Good | _onKeyEvent handles all keys |
| Radio | ❓ Not audited | | | |
| Multivideo | ❓ Not audited | | | |
| Library/Favorites | ❓ Not audited | | | |
| History | ❓ Not audited | | | |
| Subscriptions | ❓ Not audited | | | |
| Onboarding | ❓ Not audited | | | |
| Legal | ❓ Not audited | | | |
| Diagnostic | ❓ Not audited | | | |

---

## Recommended Fix Order (Atomic Commits)

### Phase 1: Manifest & Assets (1-2 commits)
1. Add TV banner assets (320x180) to drawable-xhdpi/drawable-xxxhdpi
2. Fix AndroidManifest.xml: leanback launcher, required leanback, banner

### Phase 2: Safe Area Wrapper (1 commit)
3. Create `TvSafeArea` widget with overscan insets, apply to all Scaffold bodies

### Phase 3: Core Navigation Fixes (3-4 commits)
4. Fix `CategoriesRail` - already good, verify focus styling
5. Fix `HomeShell` - wrap NavigationRail/NavigationBar destinations in Focus
6. Fix `UnifiedSettingsScreen` - make TabBar focusable, wrap ListTiles in Focus
7. Fix `SearchScreen` - add TV search delegate, conditional IME

### Phase 4: EPG Grid - Major Refactor (2-3 commits)
8. Add FocusNode per channel row, D-pad left/right for program navigation
9. Add FocusTraversalGroup for grid, program focus indicators
10. Integrate with existing `_timelineController` for jump-to-time

### Phase 5: MediaSession (2 commits)
11. Add MediaSessionCompat + MediaButtonReceiver in Android
12. Connect Flutter player to MediaSession via platform channel

### Phase 6: Audio Focus & PiP (1 commit)
13. Explicit AudioAttributes, handle audio focus loss/duck

### Phase 7: Tests & Polish (2 commits)
14. Add integration_test for TV navigation flows
15. LargeHeap, final polish

---

## Files to Modify (Priority Order)

```
android/app/src/main/AndroidManifest.xml          # P1 - Manifest
android/app/src/main/res/drawable-xhdpi/tv_banner.png   # P1 - Banner (NEW)
android/app/src/main/res/drawable-xxxhdpi/tv_banner.png # P1 - Banner (NEW)
lib/core/widgets/tv_safe_area.dart                # P2 - NEW wrapper
lib/main.dart                                     # P2 - Wrap MaterialApp
lib/features/home_shell.dart                      # P3 - Navigation focus
lib/features/settings/unified_settings_screen.dart # P3 - Settings focus
lib/features/search/search_screen.dart            # P3 - TV search
lib/features/epg/widgets/epg_grid_2d_view.dart    # P4 - EPG D-pad (MAJOR)
lib/features/player/player_screen.dart            # P5 - MediaSession bridge
android/app/src/main/java/.../MainActivity.kt     # P5 - MediaSession (NEW)
android/app/src/main/AndroidManifest.xml          # P5 - MediaButtonReceiver
lib/core/widgets/tv_focus.dart                    # P6 - Enhance TvFocus
integration_test/tv_navigation_test.dart          # P7 - Tests (NEW)
docs/TODO.md                                      # Update with TV section
```

---

## Validation Checklist Per Commit

- [ ] `flutter analyze lib` → 0 errors, 0 warnings
- [ ] `flutter test` → all pass
- [ ] `dart run tool/check_i18n_sync.dart` → 0 issues on 6 locales
- [ ] Build APK: `$env:GRADLE_USER_HOME="C:\orbitbuild\gradle_cache"; flutter build apk --release`
- [ ] Install on S20: test with TV mode forced (advanced settings → D-pad navigation)
- [ ] Verify focus visible on all interactive elements
- [ ] Verify no focus traps (can always escape with Back)
- [ ] Verify overscan-safe margins on all edges
# ezBookkeeping Mobile App - Implementation Plan

## Executive Summary

Build a native mobile app wrapper around the existing ezBookkeeping web application using **Capacitor** (by Ionic). The web app already has a polished mobile UI built with Framework7, full PWA support, and a complete REST API. Capacitor wraps this in a native shell, providing app store distribution, native device APIs (camera, biometrics, notifications, file system), and a true native app experience — while preserving 100% of existing features.

## Why Capacitor (Not Flutter/React Native Rebuild)

| Factor | Capacitor Wrapper | Flutter/React Native Rebuild |
|--------|-------------------|------------------------------|
| Feature parity | 100% — all web features work immediately | Must rebuild every screen, ~6-12 months work |
| UI quality | Already polished Framework7 mobile UI | Must redesign and rebuild all UI |
| Development time | 2-4 weeks | 6-12+ months |
| Native APIs | Via Capacitor plugins (camera, biometrics, etc.) | Direct native access |
| Maintenance | Sync with upstream web updates automatically | Must maintain separate codebase |
| Risk | Low — proven approach | High — full rewrite risk |

The existing web app's mobile UI (Framework7) already provides iOS/Android-native-like interactions including swipe gestures, pull-to-refresh, native-style navigation, and dark mode. Capacitor adds the native shell on top.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Native App Shell (Capacitor)         │
│  ┌─────────────────────────────────────────────┐ │
│  │         WebView (iOS/Android)               │ │
│  │  ┌─────────────────────────────────────┐    │ │
│  │  │   ezBookkeeping Web App             │    │ │
│  │  │   (Vue 3 + Framework7 + Pinia)      │    │ │
│  │  │                                     │    │ │
│  │  │   ┌─────────────┐ ┌─────────────┐  │    │ │
│  │  │   │ Mobile UI   │ │ Shared      │  │    │ │
│  │  │   │ (F7 Pages)  │ │ Stores/API  │  │    │ │
│  │  │   └─────────────┘ └─────────────┘  │    │ │
│  │  └─────────────────────────────────────┘    │ │
│  │         ↕ Capacitor Bridge                   │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │           Native Plugins                     │ │
│  │  • Camera (receipt scanning)                 │ │
│  │  • Biometrics (app lock)                     │ │
│  │  • Local Notifications (reminders)           │ │
│  │  • File System (import/export)               │ │
│  │  • Share (share transactions)                │ │
│  │  • Geolocation (location tracking)           │ │
│  │  • App Update (version check)                │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
                        ↕
         ┌──────────────────────────┐
         │   ezBookkeeping Server   │
         │   (Go Backend REST API)  │
         │   /api/v1/*              │
         └──────────────────────────┘
```

---

## Project Structure

```
ezbookkeeping_app/
├── app/                          # Capacitor project root
│   ├── capacitor.config.ts       # Capacitor configuration
│   ├── package.json              # Node dependencies
│   ├── src/                      # Web app source (cloned from upstream)
│   │   ├── mobile.html           # Mobile entry point
│   │   ├── MobileApp.vue         # Mobile root component
│   │   ├── views/mobile/         # Mobile UI pages
│   │   ├── stores/               # Pinia stores (shared)
│   │   ├── lib/                  # Shared business logic
│   │   ├── locales/              # i18n translations
│   │   └── ...
│   ├── android/                  # Android native project (generated)
│   ├── ios/                      # iOS native project (generated)
│   └── build/                    # Compiled web assets
├── plugins/                      # Custom Capacitor plugins (if needed)
├── docs/                         # Build/deploy documentation
├── plan.md                       # This file
└── README.md                     # Setup instructions
```

---

## Implementation Phases

### Phase 1: Project Setup & Web App Integration (Days 1-3)

**Goal**: Clone ezBookkeeping web source, configure Capacitor, build and run in simulator.

1. **Clone web source**
   - Clone `mayswind/ezbookkeeping` repo
   - Copy `src/`, `package.json`, `vite.config.ts`, `tsconfig.json` into `app/`
   - Install npm dependencies

2. **Configure Capacitor**
   - Initialize Capacitor project
   - Configure `capacitor.config.ts`:
     - App ID: `net.ezbookkeeping.app`
     - App name: `ezBookkeeping`
     - Web dir: `build` (Vite output)
     - Server URL for dev (point to self-hosted instance)
     - iOS/Android-specific settings (status bar, splash screen, etc.)

3. **Configure Vite build for Capacitor**
   - Ensure Vite builds to `app/build/`
   - Configure base path for Capacitor
   - Test build output loads in Capacitor

4. **Verify basic functionality**
   - Run on iOS Simulator
   - Run on Android Emulator
   - Confirm login flow works against demo server

### Phase 2: Native Plugin Integration (Days 4-8)

**Goal**: Add native device capabilities through Capacitor plugins.

1. **Camera Plugin** (`@capacitor/camera`)
   - Enable receipt photo capture for transaction attachments
   - Replace web file input with native camera/gallery picker
   - Handle image compression and upload

2. **Biometrics Plugin** (`@capacitor/biometric`)
   - Native Face ID / Touch ID / Fingerprint for app lock
   - Integrate with existing PIN code lock feature
   - Fallback to PIN if biometrics unavailable

3. **Local Notifications** (`@capacitor/local-notifications`)
   - Scheduled transaction reminders
   - Budget alerts
   - Daily/weekly expense logging reminders

4. **File System Plugin** (`@capacitor/filesystem`)
   - Native file import (CSV, OFX, QIF, etc.)
   - Native file export with share sheet
   - Access device storage for backup/restore

5. **Share Plugin** (`@capacitor/share`)
   - Share transaction summaries
   - Export reports to other apps

6. **Geolocation Plugin** (`@capacitor/geolocation`)
   - Native GPS for transaction location tracking
   - Better accuracy than web geolocation API
   - Background location for auto-tagging

7. **App Plugin** (`@capacitor/app`)
   - App lifecycle events (pause/resume)
   - App version detection
   - Deep linking support

8. **Keyboard Plugin** (`@capacitor/keyboard`)
   - Better keyboard handling for amount inputs
   - Avoid UI overlap with keyboard

### Phase 3: UI Enhancements (Days 9-12)

**Goal**: Polish the mobile experience beyond what the web PWA provides.

1. **Splash Screen**
   - Custom branded splash screen
   - Loading indicator while app initializes

2. **Status Bar**
   - Match status bar color to app theme
   - Light/dark mode status bar text

3. **Haptic Feedback**
   - Haptic response on button taps
   - Vibration on successful transaction save

4. **Pull-to-Refresh Enhancement**
   - Native-feeling pull-to-refresh on transaction lists
   - Sync data from server on refresh

5. **Bottom Navigation**
   - Ensure bottom tab bar follows platform conventions
   - iOS: bottom tabs, Android: bottom nav

6. **Safe Area Handling**
   - Proper inset handling for notched devices
   - Dynamic Island support on iOS

7. **Dark Mode**
   - System-level dark mode detection
   - Sync with device theme preference

### Phase 4: Offline Support & Caching (Days 13-15)

**Goal**: Make the app functional offline with smart data sync.

1. **Service Worker Configuration**
   - Configure workbox for offline caching
   - Cache static assets (JS, CSS, images)
   - Cache-first strategy for app shell

2. **Data Caching Strategy**
   - Cache recent transactions in IndexedDB
   - Cache account/category/tag lists
   - Queue offline writes for sync when online

3. **Offline Indicator**
   - Show connection status
   - Queue indicator for pending syncs

4. **Background Sync**
   - Sync pending changes when connection restored
   - Handle conflict resolution

### Phase 5: Testing & Polish (Days 16-18)

**Goal**: Comprehensive testing and final polish.

1. **Device Testing**
   - Test on real iOS devices (iPhone 12+, iPad)
   - Test on real Android devices (various manufacturers)
   - Test on low-end devices for performance

2. **Feature Verification Checklist**
   - [ ] Login / Signup / 2FA
   - [ ] Transaction CRUD (income, expense, transfer)
   - [ ] Transaction filtering and search
   - [ ] Account management (two-level)
   - [ ] Category management (two-level)
   - [ ] Tag management
   - [ ] Transaction templates
   - [ ] Scheduled transactions
   - [ ] Statistics and charts
   - [ ] Insights explorer
   - [ ] Data import (CSV, OFX, QIF, etc.)
   - [ ] Data export
   - [ ] Receipt image capture and AI recognition
   - [ ] Location tracking with maps
   - [ ] Multi-currency support
   - [ ] Exchange rate management
   - [ ] Settings and preferences
   - [ ] Profile management
   - [ ] Avatar upload
   - [ ] Application lock (PIN + biometrics)
   - [ ] Dark mode
   - [ ] Multi-language support
   - [ ] Cloud settings sync

3. **Performance Optimization**
   - Optimize WebView load time
   - Reduce splash screen duration
   - Smooth animations and transitions
   - Memory usage profiling

4. **App Store Preparation**
   - Generate app icons (all sizes)
   - Create screenshots for store listings
   - Write app descriptions
   - Configure privacy policy URL

### Phase 6: Build & Distribution (Days 19-21)

**Goal**: Build release binaries and prepare for distribution.

1. **iOS Build**
   - Configure Apple Developer account
   - Set up provisioning profiles
   - Configure code signing
   - Build .ipa for App Store / TestFlight
   - Submit for App Store review

2. **Android Build**
   - Configure signing keystore
   - Build .aab for Google Play Store
   - Configure Play Console listing
   - Submit for Play Store review

3. **Alternative Distribution**
   - Build APK for direct distribution
   - Configure F-Droid build (if desired)
   - Set up update mechanism

---

## Configuration

### Server Connection

The app will support configurable server connection:

```typescript
// capacitor.config.ts
const config: CapacitorConfig = {
  appId: 'net.ezbookkeeping.app',
  appName: 'ezBookkeeping',
  webDir: 'build',
  server: {
    // For development - point to your server
    url: 'http://YOUR_SERVER_IP:8080',
    cleartext: true,
  },
  plugins: {
    // Plugin configurations
  },
};
```

### App Settings

Users can configure:
- Server URL (self-hosted instance address)
- Authentication method (password, 2FA, OIDC)
- Theme (light/dark/auto)
- Language
- Currency
- Notification preferences

---

## Dependencies

### Core
- `@capacitor/core` — Capacitor runtime
- `@capacitor/cli` — Capacitor CLI
- `@capacitor/ios` — iOS platform
- `@capacitor/android` — Android platform

### Plugins
- `@capacitor/camera` — Camera access for receipts
- `@capacitor/biometric` — Biometric authentication
- `@capacitor/local-notifications` — Local push notifications
- `@capacitor/filesystem` — File system access
- `@capacitor/share` — Native share sheet
- `@capacitor/geolocation` — GPS location
- `@capacitor/app` — App lifecycle
- `@capacitor/keyboard` — Keyboard handling
- `@capacitor/haptics` — Haptic feedback
- `@capacitor/status-bar` — Status bar control
- `@capacitor/splash-screen` — Splash screen
- `@capacitor/safe-area` — Safe area insets

### Build Tools
- `vite` — Build tool (already used by upstream)
- `typescript` — Type checking

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| WebView compatibility issues | Medium | Test on multiple devices early; use Capacitor's built-in WebView |
| Plugin API changes | Low | Pin plugin versions; check changelogs before updating |
| App store rejection | Medium | Follow store guidelines; prepare privacy policy; test thoroughly |
| Performance on low-end devices | Medium | Optimize bundle size; lazy load heavy components |
| Upstream web app updates | Low | Re-clone and rebuild; automated CI pipeline |

---

## Success Criteria

1. App installs and runs on iOS 15+ and Android 10+
2. All existing web features work identically in the app
3. Native device features (camera, biometrics, notifications) work seamlessly
4. App startup time < 2 seconds
5. Smooth 60fps animations and transitions
6. Offline support for viewing cached data
7. App store approved on both iOS and Android

---

## Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1: Setup | 3 days | App runs in simulator |
| Phase 2: Plugins | 5 days | Native features integrated |
| Phase 3: UI Polish | 4 days | Native-feeling UX |
| Phase 4: Offline | 3 days | Offline support |
| Phase 5: Testing | 3 days | Verified on real devices |
| Phase 6: Distribution | 3 days | Store-ready builds |
| **Total** | **~21 days** | **Production-ready app** |

---

## Upstream Sync Workflow

When the ezBookkeeping team updates the web project, use the sync script to pull changes:

### Automated (GitHub Actions)
A workflow runs weekly (Monday 9:00 UTC) that:
1. Checks for upstream changes
2. Creates a PR with updates if changes exist
3. Verifies the build succeeds

Trigger manually from the **Actions** tab in GitHub.

### Manual Sync
```bash
./sync-upstream.sh
```

### What the Script Does
1. Clones/updates the upstream ezBookkeeping repo
2. Backs up our Capacitor modifications (7 modified files)
3. Copies fresh upstream source files
4. Restores our modifications on top
5. Reinstalls dependencies, rebuilds, and syncs to Android

### Files We Modified (Preserved During Sync)
| File | Modification |
|------|-------------|
| `src/lib/capacitor.ts` | Native feature bridge (NEW - not in upstream) |
| `src/MobileApp.vue` | Capacitor initialization |
| `src/core/setting.ts` | Added `applicationLockBiometric` setting |
| `src/stores/setting.ts` | Added `setApplicationLockBiometric` method |
| `src/views/mobile/transactions/EditPage.vue` | Native camera integration |
| `src/views/mobile/ApplicationLockPage.vue` | Biometric auth toggle |
| `src/views/mobile/UnlockPage.vue` | Biometric unlock |
| `src/components/mobile/AIImageRecognitionSheet.vue` | Native camera for AI |

### Manual Sync (If Script Fails)
```bash
# 1. Update upstream
cd /tmp/ezbookkeeping_upstream && git pull

# 2. Copy changed files manually
cp /tmp/ezbookkeeping_upstream/src/views/mobile/SomeFile.vue app/src/views/mobile/

# 3. Rebuild
cd app && npm install && npm run build && npx cap sync android
```

### Conflict Resolution
If upstream changes conflict with our modifications:
1. The script backs up to `/tmp/ezbookkeeping_backup_<timestamp>/`
2. Compare files manually: `diff <original> <upstream>`
3. Merge changes carefully, preserving Capacitor integrations
4. Test thoroughly after resolving conflicts

---

## Future Enhancements (Post-Launch)

- Widget support (iOS/Android home screen widgets for quick expense entry)
- Apple Watch / Wear OS companion app
- Siri / Google Assistant shortcuts
- Drag-and-drop support (iPad)
- Multi-window support (Android tablets)
- App Clips (iOS) / Instant Apps (Android)

# ezBookkeeping Mobile App

Native Android wrapper for [ezBookkeeping](https://github.com/mayswind/ezbookkeeping) built with [Capacitor](https://capacitorjs.com/).

**ezBookkeeping** is a lightweight, self-hosted personal finance app — open source, MIT licensed, with powerful bookkeeping features like transactions, two-level accounts & categories, statistics & charts, scheduled transactions, receipt AI recognition, multi-currency, and data import/export.

This project takes that web app and wraps it in a native Android shell, so you get:

- 📱 A real installable Android APK (not just a browser bookmark)
- 📷 Native camera access (receipt scanning, AI image recognition)
- 🔒 Biometric unlock (fingerprint / face unlock for the app lock)
- 🔔 Local notifications (scheduled transaction reminders)
- 📍 Native GPS geolocation (location tracking for transactions)
- 📂 Native file picker & file system (import/export)
- ✨ Haptic feedback, splash screen, proper status bar & safe-area handling
- 🔄 **Fully automated**: whenever ezBookkeeping releases a new version, a GitHub Action builds and publishes a fresh APK automatically

---

## Table of Contents

- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Quick Start (Build Locally)](#quick-start-build-locally)
- [Installing the APK](#installing-the-apk)
- [Automated Releases](#automated-releases)
- [Syncing Upstream Changes](#syncing-upstream-changes)
- [Native Features](#native-features)
- [Modified Files vs Upstream](#modified-files-vs-upstream)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Special Thanks](#special-thanks)

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│            Native Android App (Capacitor)        │
│  ┌─────────────────────────────────────────────┐ │
│  │        WebView (Android System WebView)     │ │
│  │  ┌─────────────────────────────────────┐    │ │
│  │  │   ezBookkeeping Web App             │    │ │
│  │  │   (Vue 3 + Framework7 + Pinia)      │    │ │
│  │  │   — Mobile UI already built &       │    │ │
│  │  │     optimized for phones             │    │ │
│  │  └─────────────────────────────────────┘    │ │
│  │         ↕ Capacitor Bridge                   │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │       Native Plugins (13 installed)          │ │
│  │  Camera · Biometrics · Notifications ·       │ │
│  │  Filesystem · Share · Geolocation · Haptics  │ │
│  │  Status Bar · Splash Screen · Safe Area ·    │ │
│  │  File Picker · App · Keyboard                │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
                      ↕ HTTPS
      ┌──────────────────────────────┐
      │    Your ezBookkeeping        │
      │    Server (self-hosted)      │
      │    Go backend + REST API     │
      └──────────────────────────────┘
```

**Why a wrapper instead of a native rebuild?**

| Factor | Capacitor Wrapper | Flutter/React Native Rebuild |
|--------|-------------------|------------------------------|
| Feature parity | 100% — all web features work immediately | Must rebuild every screen, months of work |
| UI quality | Already-polished Framework7 mobile UI | Must redesign and rebuild all UI |
| Development time | ~3 weeks | 6-12+ months |
| Maintenance | Upstream updates sync automatically | Separate codebase to maintain forever |
| Risk | Low — proven approach | High — full rewrite risk |

The web app's mobile interface (Framework7) already provides native-style interactions: swipe gestures, pull-to-refresh, page transitions, and dark mode. Capacitor adds the native shell and device capabilities on top.

**Note:** This app does not host the backend. You connect it to your own self-hosted ezBookkeeping server (Docker, binary, NAS, Raspberry Pi, etc.).

---

## Project Structure

```
ezbookkeeping_app/
├── .github/workflows/
│   ├── release-upstream.yml   # Auto-builds & publishes APK when upstream changes
│   └── sync-upstream.yml      # Weekly PR sync of upstream code changes
├── app/                       # Capacitor project root
│   ├── capacitor.config.ts    # Native shell configuration (ours)
│   ├── package.json           # Web app + Capacitor dependencies
│   ├── src/                   # ezBookkeeping web app source (Vue 3)
│   │   ├── MobileApp.vue      # Mobile app entry (Capacitor-aware)
│   │   ├── lib/capacitor.ts   # ⭐ Our native feature bridge (ours)
│   │   ├── views/mobile/      # Framework7 mobile screens
│   │   ├── stores/            # Pinia state management
│   │   └── ...                # (copied from upstream)
│   └── android/               # Native Android project (Gradle)
│       └── app/build/outputs/apk/debug/app-debug.apk  ← the APK
├── vendor-base/               # Pristine upstream copies of our 7 modified files
│                               # (used as merge base during syncs)
├── scripts/
│   ├── sync-capacitor-mods.sh # 3-way merge: re-apply our changes onto upstream
│   ├── update-vendor-base.sh  # Refresh vendor-base after a successful sync
│   └── install-capacitor-deps.sh # Re-install Capacitor plugins after upstream overwrite
├── plan.md                    # Detailed implementation plan
├── sync-upstream.sh           # Manual upstream sync script
└── README.md                  # This file
```

---

## Quick Start (Build Locally)

Prerequisites: **Node.js 22+** (Capacitor CLI requires ≥22), **Java 21**, **Android SDK**.

```bash
# 1. Install web app dependencies
cd app
npm install

# 2. Build web assets (creates dist/)
NODE_ENV=production npx vite build

# 3. Sync web assets into the Android project
npx cap sync android

# 4. Build the debug APK
cd android
./gradlew assembleDebug
```

The APK will be at:

```
app/android/app/build/outputs/apk/debug/app-debug.apk
```

---

## Installing the APK

1. Copy `app-debug.apk` to your Android phone (or download it from a GitHub Release).
2. On the phone, open the file.
3. If prompted, enable **"Install unknown apps"** for your file manager/browser.
4. Tap **Install**.

> The debug APK is signed with Android's standard debug keystore, so no special setup is needed to sideload it. For Play Store distribution you'd need a proper release keystore.

### Connecting to Your Server

After installing, open the app and log in with your self-hosted ezBookkeeping server. All features work against your server — the app never stores your data in the cloud.

---

## Automated Releases

This project has a **fully automated release pipeline** — you don't have to do anything.

**Workflow: `release-upstream.yml`** (runs every 6 hours, or on demand from the Actions tab)

1. Checks the latest ezBookkeeping upstream `main` HEAD via git.
2. If the upstream code changed since our last build, it:
   - Clones the latest upstream code
   - Re-applies our Capacitor modifications via **3-way merge**
   - Installs dependencies (including Capacitor plugins) and builds the web assets
   - Syncs to Android and builds the debug APK
   - **Creates a GitHub Release** with the APK attached
3. Already-built upstream commits are skipped (tracked via `upstream-<sha>` git tags).

**Result:** Every time ezBookkeeping ships new code, you get a fresh `ezBookkeeping-<version>-debug.apk` release automatically.

### GitHub Release Format
- **Release tag:** `upstream-<short-sha>`
- **APK file:** `ezBookkeeping-<version>-debug.apk`
- **Notes:** auto-generated install instructions

### How our changes survive the sync
Our Capacitor integration touches 7 upstream files plus 2 files that are entirely ours. Instead of blindly overwriting, the sync uses a **3-way merge** (`scripts/sync-capacitor-mods.sh`):

- **base** = pristine upstream version our changes were based on (`vendor-base/`)
- **ours** = our modified version (committed)
- **theirs** = fresh upstream code

If upstream changed the same code, the merge combines both sides. If they conflict, the workflow **fails loudly** (instead of shipping a broken build) and the conflict must be resolved and the `vendor-base` refreshed via `scripts/update-vendor-base.sh`.

---

## Syncing Upstream Changes

### Option 1 — Auto (GitHub Actions, recommended)
The **sync** workflow creates a PR every Monday with upstream code changes (build-verified). The **release** workflow (above) also pulls in new code whenever a version is tagged.

### Option 2 — Manual script
```bash
./sync-upstream.sh
```
This clones/updates upstream, copies the fresh source, re-applies our Capacitor modifications via 3-way merge, reinstalls dependencies (including Capacitor plugins), and rebuilds everything.

### How conflicts are avoided
Our Capacitor integration touches only **7 known files** (see below). The sync performs a 3-way merge of each against the pristine upstream base (`vendor-base/`), so upstream updates flow in without clobbering our native integrations. Files that are entirely ours (`src/lib/capacitor.ts`, `capacitor.config.ts`) are simply re-copied.

---

## Native Features

| Capacitor Plugin | Feature | Where it's used |
|------------------|---------|-----------------|
| `@capacitor/camera` | Take/choose photos | Receipt attachments, AI image recognition |
| `@aparajita/capacitor-biometric-auth` | Fingerprint / Face unlock | App lock, unlock screen |
| `@capacitor/local-notifications` | Local notifications | Scheduled transaction reminders |
| `@capacitor/filesystem` | File save/open | Data import/export |
| `@capawesome/capacitor-file-picker` | Native file picker | Import transaction files (CSV, OFX, QIF…) |
| `@capacitor/share` | Share sheet | Share data to other apps |
| `@capacitor/geolocation` | GPS location | Transaction location tracking |
| `@capacitor/haptics` | Haptic feedback | Button taps, save confirmation |
| `@capacitor/status-bar` | Status bar control | Theme-matched status bar |
| `@capacitor/splash-screen` | Splash screen | Branded launch screen |
| `@capacitor/keyboard` | Keyboard handling | Avoids UI overlap |
| `@capacitor/app` | App lifecycle | Resume/pause events |
| `capacitor-plugin-safe-area` | Safe area insets | Notch / gesture-bar handling |

---

## Modified Files vs Upstream

These are the files where we add native behavior on top of the upstream code. They're merged during every sync via `scripts/sync-capacitor-mods.sh`:

| File | What we changed | Sync handling |
|------|-----------------|---------------|
| `app/src/lib/capacitor.ts` | Native feature bridge | Own file — always re-copied |
| `app/capacitor.config.ts` | Capacitor configuration | Own file — always re-copied |
| `app/src/MobileApp.vue` | Capacitor initialization (status bar, splash, keyboard) | 3-way merge |
| `app/src/core/setting.ts` | Added `applicationLockBiometric` setting | 3-way merge |
| `app/src/stores/setting.ts` | Added `setApplicationLockBiometric` method | 3-way merge |
| `app/src/views/mobile/transactions/EditPage.vue` | Native camera for receipt photos | 3-way merge |
| `app/src/views/mobile/ApplicationLockPage.vue` | Biometric auth toggle | 3-way merge |
| `app/src/views/mobile/UnlockPage.vue` | Biometric unlock | 3-way merge |
| `app/src/components/mobile/AIImageRecognitionSheet.vue` | Native camera for AI receipt recognition | 3-way merge |
| `app/android/.../AndroidManifest.xml` | Native permissions (camera, biometrics, location, etc.) | Kept as-is (never overwritten) |

---

## Troubleshooting

**Build fails with "invalid source release: 21"**
→ You're using Java 17. Capacitor 8 requires **Java 21**. Install it (`brew install openjdk@21` on macOS) and set `JAVA_HOME`.

**App can't connect to server**
→ Make sure your ezBookkeeping server is reachable and you're using `http://` for local LAN servers. For `http://` (non-TLS) connections on Android, the server URL must be reachable over the same network.

**Camera doesn't open**
→ Grant the camera permission when the app asks. Also check the app's camera permission in Android Settings.

**Biometric unlock doesn't appear**
→ Enable **Application Lock** first (Settings → App Lock), then the biometric toggle appears. Your device must have a fingerprint/face registered.

---

## License

MIT License — same as the upstream [ezBookkeeping](https://github.com/mayswind/ezbookkeeping) project.

---

## Special Thanks

🙏 A huge **thank you** to **[MaysWind](https://github.com/mayswind)** and all the [contributors](https://github.com/mayswind/ezbookkeeping/graphs/contributors) of **ezBookkeeping** for creating and maintaining such a wonderful open-source project.

This app would not exist without your hard work. ezBookkeeping is:
- ⭐ A lightweight, self-hosted, privacy-first personal finance app
- 🌍 Localized into 18+ languages
- 🛠️ Actively maintained and growing (receipt AI recognition, MCP support, agent skills, and more)
- 💖 Open source and MIT licensed

If you find this app useful, please consider:
- ⭐ **Starring** [ezBookkeeping on GitHub](https://github.com/mayswind/ezbookkeeping)
- 🍴 Contributing to the [ezBookkeeping project](https://github.com/mayswind/ezbookkeeping) (translations, bug reports, code)
- ☕ Supporting the developer

**Thank you for sharing your work with the world.**

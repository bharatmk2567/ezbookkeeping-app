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
│   ├── release-upstream.yml   # Auto-builds & publishes APK on upstream releases
│   └── sync-upstream.yml      # Weekly PR sync of upstream code changes
├── app/                       # Capacitor project root
│   ├── capacitor.config.ts    # Native shell configuration
│   ├── package.json           # Web app + Capacitor dependencies
│   ├── src/                   # ezBookkeeping web app source (Vue 3)
│   │   ├── MobileApp.vue      # Mobile app entry (Capacitor-aware)
│   │   ├── lib/capacitor.ts   # ⭐ Our native feature bridge
│   │   ├── views/mobile/      # Framework7 mobile screens
│   │   ├── stores/            # Pinia state management
│   │   └── ...                # (copied from upstream)
│   └── android/               # Native Android project (Gradle)
│       └── app/build/outputs/apk/debug/app-debug.apk  ← the APK
├── plan.md                    # Detailed implementation plan
├── sync-upstream.sh           # Manual upstream sync script
└── README.md                  # This file
```

---

## Quick Start (Build Locally)

Prerequisites: **Node.js 20+**, **Java 21**, **Android SDK**.

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

1. Checks the latest ezBookkeeping upstream release (`v1.6.x`, `v1.7.x`, …) via the GitHub API.
2. If it's a version we haven't packaged yet, it:
   - Clones the upstream code at that release tag
   - Backs up & re-applies our Capacitor modifications
   - Installs dependencies and builds the web assets
   - Syncs to Android and builds the debug APK
   - **Creates a GitHub Release** with the APK attached
3. Already-packaged versions are skipped (tracked via `upstream-v<version>` git tags).

**Result:** Every time ezBookkeeping ships a new version, you get a fresh `ezBookkeeping-<version>-debug.apk` release automatically.

### GitHub Release Format
- **Release tag:** `upstream-v1.6.1`
- **APK file:** `ezBookkeeping-1.6.1-debug.apk`
- **Notes:** auto-generated install instructions

---

## Syncing Upstream Changes

### Option 1 — Auto (GitHub Actions, recommended)
The **sync** workflow creates a PR every Monday with upstream code changes (build-verified). The **release** workflow (above) also pulls in new code whenever a version is tagged.

### Option 2 — Manual script
```bash
./sync-upstream.sh
```
This clones/updates upstream, backs up our Capacitor modifications, copies the fresh source, restores our changes, and rebuilds everything.

### How conflicts are avoided
Our Capacitor integration touches only **8 known files** (see below). The sync scripts back those files up before copying upstream, then restore them afterward — so upstream updates flow in without clobbering our native integrations.

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

These are the only files where we add native behavior on top of the upstream code:

| File | What we changed |
|------|-----------------|
| `app/src/lib/capacitor.ts` | **New** — native feature bridge module |
| `app/src/MobileApp.vue` | Capacitor initialization (status bar, splash, keyboard) |
| `app/src/core/setting.ts` | Added `applicationLockBiometric` setting |
| `app/src/stores/setting.ts` | Added `setApplicationLockBiometric` method |
| `app/src/views/mobile/transactions/EditPage.vue` | Native camera for receipt photos |
| `app/src/views/mobile/ApplicationLockPage.vue` | Biometric auth toggle |
| `app/src/views/mobile/UnlockPage.vue` | Biometric unlock |
| `app/src/components/mobile/AIImageRecognitionSheet.vue` | Native camera for AI receipt recognition |
| `app/capacitor.config.ts` | **New** — Capacitor configuration |
| `app/android/.../AndroidManifest.xml` | Native permissions (camera, biometrics, location, etc.) |

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

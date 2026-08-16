# ezBookkeeping Mobile App

Native Android wrapper for [ezBookkeeping](https://github.com/mayswind/ezbookkeeping) using Capacitor.

## Quick Start

```bash
# Install dependencies
cd app && npm install

# Build web assets
NODE_ENV=production npx vite build

# Sync to Android
npx cap sync android

# Build APK
cd android && ./gradlew assembleDebug
```

## Sync with Upstream

### Automated (GitHub Actions)
The workflow runs **every Monday at 9:00 UTC** and:
1. Checks for upstream changes
2. Creates a PR with updates if changes exist
3. Verifies the build succeeds

You can also trigger it manually from the **Actions** tab.

### Manual
```bash
./sync-upstream.sh
```

## Modified Files (vs upstream)

These files contain our Capacitor integration changes:

- `app/src/lib/capacitor.ts` — Native feature bridge
- `app/src/MobileApp.vue` — Capacitor initialization
- `app/src/core/setting.ts` — Biometric setting
- `app/src/stores/setting.ts` — Biometric store method
- `app/src/views/mobile/transactions/EditPage.vue` — Native camera
- `app/src/views/mobile/ApplicationLockPage.vue` — Biometric toggle
- `app/src/views/mobile/UnlockPage.vue` — Biometric unlock
- `app/src/components/mobile/AIImageRecognitionSheet.vue` — Native camera for AI

## APK Location

```
app/android/app/build/outputs/apk/debug/app-debug.apk
```

## License

MIT (same as upstream ezBookkeeping)

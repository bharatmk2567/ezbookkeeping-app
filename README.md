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

### Automated Release (GitHub Actions)
The **Release APK from Upstream** workflow runs **every 6 hours** and:
1. Checks for new ezBookkeeping upstream releases (`v*` tags)
2. If a new release exists, pulls the code changes
3. Applies our Capacitor modifications on top
4. Builds the app
5. Publishes the APK as a GitHub **Release** (no signing key needed — uses Android debug keystore)

Release tags look like `upstream-v1.6.1`, APKs are named `ezBookkeeping-<version>-debug.apk`.

### Sync-Only Workflow (GitHub Actions)
The **Sync Upstream ezBookkeeping** workflow runs **every Monday** and creates a PR with changes (doesn't release).

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

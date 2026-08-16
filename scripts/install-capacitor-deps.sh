#!/bin/bash
# Install Capacitor dependencies on top of upstream's package.json.
#
# Upstream's package.json does not include our native plugins, and the sync
# process replaces our package.json with upstream's. Run this after `npm install`
# to add all Capacitor packages we depend on.

set -e

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Installing Capacitor dependencies ==="

npm install \
    @capacitor/core@^8 \
    @capacitor/cli@^8 \
    @capacitor/android@^8 \
    @capacitor/camera@^8 \
    @capacitor/app@^8 \
    @capacitor/filesystem@^8 \
    @capacitor/geolocation@^8 \
    @capacitor/haptics@^8 \
    @capacitor/keyboard@^8 \
    @capacitor/local-notifications@^8 \
    @capacitor/share@^8 \
    @capacitor/splash-screen@^8 \
    @capacitor/status-bar@^8 \
    @aparajita/capacitor-biometric-auth@^10 \
    @capawesome/capacitor-file-picker@^8 \
    capacitor-plugin-safe-area@^5

echo "Capacitor dependencies installed."

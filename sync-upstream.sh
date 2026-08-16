#!/bin/bash
# Sync upstream ezBookkeeping changes
# Usage: ./sync-upstream.sh

set -e

UPSTREAM_URL="https://github.com/mayswind/ezbookkeeping.git"
UPSTREAM_DIR="/tmp/ezbookkeeping_upstream"
APP_DIR="$(cd "$(dirname "$0")/app" && pwd)"

echo "=== ezBookkeeping Upstream Sync ==="

# Step 1: Clone or update upstream
if [ -d "$UPSTREAM_DIR" ]; then
    echo "[1/4] Updating upstream clone..."
    cd "$UPSTREAM_DIR"
    git fetch --depth 1 origin main
    git reset --hard origin/main
else
    echo "[1/4] Cloning upstream..."
    git clone --depth 1 "$UPSTREAM_URL" "$UPSTREAM_DIR"
    cd "$UPSTREAM_DIR"
fi

UPSTREAM_COMMIT=$(git rev-parse --short HEAD)
echo "       Upstream commit: $UPSTREAM_COMMIT"

# Step 2: Show what changed
echo "[2/4] Checking for changes in src/ ..."
cd "$APP_DIR"
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)

# Step 3: Backup our modifications
echo "[3/4] Backing up custom modifications..."
BACKUP_DIR="/tmp/ezbookkeeping_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Files we modified (Capacitor integration)
CUSTOM_FILES=(
    "src/lib/capacitor.ts"
    "src/MobileApp.vue"
    "src/core/setting.ts"
    "src/stores/setting.ts"
    "src/views/mobile/transactions/EditPage.vue"
    "src/views/mobile/ApplicationLockPage.vue"
    "src/views/mobile/UnlockPage.vue"
    "src/components/mobile/AIImageRecognitionSheet.vue"
    "capacitor.config.ts"
)

for file in "${CUSTOM_FILES[@]}"; do
    if [ -f "$APP_DIR/$file" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$APP_DIR/$file" "$BACKUP_DIR/$file"
        echo "       Backed up: $file"
    fi
done

# Step 4: Copy upstream files (excluding our custom files)
echo "[4/4] Copying upstream changes..."

# Files/dirs to copy from upstream
COPY_ITEMS=(
    "src"
    "package.json"
    "package-lock.json"
    "vite.config.ts"
    "tsconfig.json"
    "eslint.config.mjs"
    "postcss.config.js"
    "vitest.config.ts"
    "public"
    "LICENSE"
    "contributors.json"
    "third-party-dependencies.json"
)

for item in "${COPY_ITEMS[@]}"; do
    if [ -e "$UPSTREAM_DIR/$item" ]; then
        rm -rf "$APP_DIR/$item"
        cp -r "$UPSTREAM_DIR/$item" "$APP_DIR/$item"
        echo "       Updated: $item"
    fi
done

# Step 5: Restore our modifications
echo ""
echo "=== Restoring Capacitor modifications ==="
for file in "${CUSTOM_FILES[@]}"; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        mkdir -p "$(dirname "$APP_DIR/$file")"
        cp "$BACKUP_DIR/$file" "$APP_DIR/$file"
        echo "       Restored: $file"
    fi
done

# Step 6: Install dependencies and rebuild
echo ""
echo "=== Reinstalling dependencies ==="
cd "$APP_DIR"
npm install 2>&1 | tail -3

echo ""
echo "=== Rebuilding web assets ==="
NODE_ENV=production npx vite build 2>&1 | tail -5

echo ""
echo "=== Syncing to Android ==="
npx cap sync android 2>&1 | tail -5

echo ""
echo "=== Done! ==="
echo "Upstream commit: $UPSTREAM_COMMIT"
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Test the app to verify everything works"
echo "  2. Check for any merge conflicts in modified files"
echo "  3. If issues, restore from backup: $BACKUP_DIR"

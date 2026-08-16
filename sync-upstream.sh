#!/bin/bash
# Sync upstream ezBookkeeping changes locally.
# Usage: ./sync-upstream.sh

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM_URL="https://github.com/mayswind/ezbookkeeping.git"
UPSTREAM_DIR="/tmp/ezbookkeeping_upstream"

echo "=== ezBookkeeping Upstream Sync ==="

# Step 1: Clone or update upstream
if [ -d "$UPSTREAM_DIR/.git" ]; then
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

# Step 2: Copy upstream files into app/
echo "[2/4] Copying upstream files..."

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
        rm -rf "$ROOT_DIR/app/$item"
        cp -r "$UPSTREAM_DIR/$item" "$ROOT_DIR/app/$item"
        echo "       Updated: $item"
    fi
done

# Step 3: Apply our Capacitor modifications via 3-way merge
echo "[3/4] Applying Capacitor modifications (3-way merge)..."
bash "$ROOT_DIR/scripts/sync-capacitor-mods.sh" "$UPSTREAM_DIR"

# Step 4: Install dependencies and rebuild
echo "[4/4] Reinstalling dependencies and rebuilding..."
cd "$ROOT_DIR/app"
npm install 2>&1 | tail -3
bash "$ROOT_DIR/scripts/install-capacitor-deps.sh"
NODE_ENV=production npx vite build 2>&1 | tail -5
npx cap sync android 2>&1 | tail -5

echo ""
echo "=== Done! ==="
echo "Upstream commit: $UPSTREAM_COMMIT"
echo ""
echo "If the 3-way merge reported conflicts, resolve them in app/ then re-run:"
echo "  bash scripts/sync-capacitor-mods.sh $UPSTREAM_DIR"
echo ""
echo "After a successful sync, update the merge base for future syncs:"
echo "  bash scripts/update-vendor-base.sh $UPSTREAM_DIR"

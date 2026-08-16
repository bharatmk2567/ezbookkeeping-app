#!/bin/bash
# Regenerate vendor-base from the pristine upstream source.
# Run this AFTER syncing upstream and merging our changes successfully,
# so future 3-way merges use the new upstream code as base.
# Usage: ./scripts/update-vendor-base.sh [path-to-upstream-src]

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_BASE_DIR="$ROOT_DIR/vendor-base"

UPSTREAM_SRC="${1:-/tmp/upstream/src}"

MODIFIED_FILES=(
    "src/MobileApp.vue"
    "src/core/setting.ts"
    "src/stores/setting.ts"
    "src/views/mobile/transactions/EditPage.vue"
    "src/views/mobile/ApplicationLockPage.vue"
    "src/views/mobile/UnlockPage.vue"
    "src/components/mobile/AIImageRecognitionSheet.vue"
)

echo "=== Updating vendor-base from upstream ==="
echo "Upstream source: $UPSTREAM_SRC"

for file in "${MODIFIED_FILES[@]}"; do
    if [ -f "$UPSTREAM_SRC/$file" ]; then
        mkdir -p "$(dirname "$VENDOR_BASE_DIR/$file")"
        cp "$UPSTREAM_SRC/$file" "$VENDOR_BASE_DIR/$file"
        echo "  Updated base: $file"
    else
        echo "  WARNING: upstream no longer has $file — leaving base unchanged"
    fi
done

echo ""
echo "vendor-base updated. Commit the changes along with the merged app code."

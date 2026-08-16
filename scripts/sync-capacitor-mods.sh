#!/bin/bash
# Apply our Capacitor modifications onto fresh upstream code using 3-way merge.
#
# Run this AFTER copying upstream source into app/ (which overwrites our
# modified files). This script restores our modifications on top of the
# new upstream code.
#
# Usage: ./scripts/sync-capacitor-mods.sh [path-to-upstream-repo-root]
#
# For each modified file this performs a 3-way merge:
#   base   = vendor-base/<file>      (pristine upstream our mods were based on)
#   ours   = git HEAD:app/<file>     (our committed modified version)
#   theirs = <UPSTREAM>/<file>       (fresh upstream being synced)
#
# Result is written to app/<file>. Conflicts leave markers and exit non-zero.

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
VENDOR_BASE_DIR="$ROOT_DIR/vendor-base"

UPSTREAM_ROOT="${1:-/tmp/upstream}"

# Files that carry our Capacitor/native modifications (upstream files we patched)
MODIFIED_FILES=(
    "src/MobileApp.vue"
    "src/core/setting.ts"
    "src/stores/setting.ts"
    "src/views/mobile/transactions/EditPage.vue"
    "src/views/mobile/ApplicationLockPage.vue"
    "src/views/mobile/UnlockPage.vue"
    "src/components/mobile/AIImageRecognitionSheet.vue"
)

# Files that are entirely ours (never in upstream) — restored from git HEAD
OWN_FILES=(
    "src/lib/capacitor.ts"
    "capacitor.config.ts"
)

echo "=== Applying Capacitor modifications (3-way merge) ==="
echo "Upstream root: $UPSTREAM_ROOT"

CONFLICT=false
TMPDIR_EBK="/tmp/ebk_merge"
mkdir -p "$TMPDIR_EBK"

# Ensure we're in the git repo
if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: must run inside the git repository"
    exit 1
fi

echo ""
echo "[1/3] Restoring own files from git HEAD..."
for file in "${OWN_FILES[@]}"; do
    if git -C "$ROOT_DIR" cat-file -e "HEAD:app/$file" 2>/dev/null; then
        mkdir -p "$(dirname "$APP_DIR/$file")"
        git -C "$ROOT_DIR" show "HEAD:app/$file" > "$APP_DIR/$file"
        echo "  Restored: $file"
    else
        echo "  WARNING: $file not found in git HEAD — keeping whatever is present"
    fi
done

echo ""
echo "[2/3] Merging modified files..."
for file in "${MODIFIED_FILES[@]}"; do
    theirs="$UPSTREAM_ROOT/$file"
    target="$APP_DIR/$file"

    # ours = our committed version
    if ! git -C "$ROOT_DIR" cat-file -e "HEAD:app/$file" 2>/dev/null; then
        echo "  WARNING: $file not in git HEAD — copying upstream version"
        mkdir -p "$(dirname "$target")"
        if [ -f "$theirs" ]; then
            cp "$theirs" "$target"
        fi
        continue
    fi
    git -C "$ROOT_DIR" show "HEAD:app/$file" > "$TMPDIR_EBK/ours"

    # base = pristine upstream our mods were based on
    if [ ! -f "$VENDOR_BASE_DIR/$file" ]; then
        echo "  WARNING: no vendor-base for $file — using our version as-is"
        mkdir -p "$(dirname "$target")"
        cp "$TMPDIR_EBK/ours" "$target"
        continue
    fi
    cp "$VENDOR_BASE_DIR/$file" "$TMPDIR_EBK/base"

    # theirs = fresh upstream
    if [ ! -f "$theirs" ]; then
        echo "  WARNING: upstream no longer has $file — keeping our version"
        mkdir -p "$(dirname "$target")"
        cp "$TMPDIR_EBK/ours" "$target"
        continue
    fi
    cp "$theirs" "$TMPDIR_EBK/theirs"

    mkdir -p "$(dirname "$target")"

    if git merge-file -p "$TMPDIR_EBK/ours" "$TMPDIR_EBK/base" "$TMPDIR_EBK/theirs" > "$TMPDIR_EBK/merged" 2>/dev/null; then
        cp "$TMPDIR_EBK/merged" "$target"
        echo "  Merged: $file"
    else
        cp "$TMPDIR_EBK/merged" "$target"
        echo "  CONFLICT in $file — resolve manually (conflict markers present)"
        CONFLICT=true
    fi
done

echo ""
echo "[3/3] Verifying no conflict markers remain..."
if grep -rE '^(<<<<<<<|>>>>>>>|=======)$' "$APP_DIR/src" >/dev/null 2>&1; then
    echo "ERROR: conflict markers found in $APP_DIR/src"
    exit 1
fi

if [ "$CONFLICT" = true ]; then
    echo "ERROR: 3-way merge produced conflicts. Resolve them in app/ then re-run."
    exit 1
fi

echo ""
echo "Capacitor modifications applied successfully."

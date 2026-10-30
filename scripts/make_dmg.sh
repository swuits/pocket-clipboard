#!/usr/bin/env bash
# Packages build/Pocket.app into dist/Pocket-<version>.dmg with a drag-to-Applications layout.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
export VERSION
./scripts/build.sh

DMG="dist/Pocket-$VERSION.dmg"
STAGE="$(mktemp -d)"
RW="$(mktemp -d)/pocket-rw.dmg"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p dist build
rm -f "$DMG"
cp -R build/Pocket.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "▸ Creating $DMG"
hdiutil create -volname "Pocket" -srcfolder "$STAGE" -ov -format UDRW -fs HFS+ "$RW" >/dev/null

# Best-effort Finder layout (icon positions). Skipped silently if Finder scripting is denied.
MOUNT="$(hdiutil attach "$RW" -nobrowse -noverify | awk -F'\t' '/\/Volumes\//{print $NF}')"
timeout 20 osascript >/dev/null 2>&1 <<OSA || echo "  (Finder layout skipped)"
tell application "Finder"
    tell disk "Pocket"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 140, 740, 480}
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 112
        set position of item "Pocket.app" of container window to {140, 160}
        set position of item "Applications" of container window to {400, 160}
        close
    end tell
end tell
OSA
sync
hdiutil detach "$MOUNT" >/dev/null || hdiutil detach "$MOUNT" -force >/dev/null

hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW"
echo "✓ $DMG ($(du -h "$DMG" | cut -f1))"

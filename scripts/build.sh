#!/usr/bin/env bash
# Builds build/Pocket.app (universal, ad-hoc signed). Needs only the Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
APP="build/Pocket.app"

echo "▸ Compiling (release, arm64 + x86_64)"
if ! swift build -c release --arch arm64 --arch x86_64 >/dev/null 2>&1; then
    echo "  universal build unavailable, falling back to native arch"
    swift build -c release
    BIN="$(swift build -c release --show-bin-path)/Pocket"
else
    BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Pocket"
fi

echo "▸ Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Pocket"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Signing (ad-hoc)"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=1 "$APP" 2>&1 | sed 's/^/  /'
echo "✓ $APP"

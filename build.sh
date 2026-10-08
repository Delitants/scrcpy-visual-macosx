#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT_APP=${OUT_APP:-"$ROOT/dist/Scrcpy Visual.app"}
CONTENTS="$OUT_APP/Contents"

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
swiftc -parse-as-library -O -framework SwiftUI -framework AppKit \
  -o "$CONTENTS/MacOS/ScrcpyVisual" \
  "$ROOT/Sources/FireTVRemote.swift"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>ScrcpyVisual</string>
  <key>CFBundleIdentifier</key><string>com.delitants.ScrcpyVisual</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Scrcpy Visual</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1.1</string>
  <key>CFBundleVersion</key><string>4</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleIconFile</key>
  <string>ScrcpyVisual.icns</string>
</dict>
</plist>
PLIST

if [ -n "${SCRCPY_DIR:-}" ]; then
  mkdir -p "$CONTENTS/Resources/scrcpy"
  cp -R "$SCRCPY_DIR"/. "$CONTENTS/Resources/scrcpy/"
fi

printf 'Built %s\n' "$OUT_APP"

/bin/cp assets/ScrcpyVisual.icns "$CONTENTS/Resources/ScrcpyVisual.icns"

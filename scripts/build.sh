#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$REPO_ROOT/build/NotchMate.app"
DIST_DIR="$REPO_ROOT/dist"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/NotchMate"

mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$DIST_DIR"

swiftc \
  -parse-as-library \
  -O \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework ServiceManagement \
  "$REPO_ROOT/NotchMate/NotchMate.swift" \
  -o "$EXECUTABLE"

cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>NotchMate</string>
  <key>CFBundleIdentifier</key><string>com.notchmate.app</string>
  <key>CFBundleName</key><string>NotchMate</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"
ditto -c -k --sequesterRsrc --keepParent \
  "$APP_BUNDLE" "$DIST_DIR/NotchMate-macOS-arm64.zip"

echo "Built: $APP_BUNDLE"
echo "Packaged: $DIST_DIR/NotchMate-macOS-arm64.zip"

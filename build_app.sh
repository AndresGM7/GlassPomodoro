#!/bin/bash
# build_app.sh — Compila GlassPomodoro.app sin Xcode ni SPM
set -e
cd "$(dirname "$0")"

APP="GlassPomodoro"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP.app"

echo "→ Compiling..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc \
  -O \
  -target arm64-apple-macosx14.0 \
  -parse-as-library \
  Sources/GlassPomodoro/*.swift \
  -framework SwiftUI \
  -framework AppKit \
  -o "$APP_DIR/Contents/MacOS/$APP"

echo "→ Writing Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>GlassPomodoro</string>
    <key>CFBundleIdentifier</key><string>com.andresgm.glasspomodoro</string>
    <key>CFBundleName</key><string>GlassPomodoro</string>
    <key>CFBundleDisplayName</key><string>GroovinApps Pomodoro</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "→ Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_DIR"

echo "✓ Built: $APP_DIR"
echo "  Run:   open $APP_DIR"
echo "  Share: zip -r $APP.zip $APP_DIR"

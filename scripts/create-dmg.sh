#!/bin/bash

# Script to create a DMG file for OzLand
# Usage: ./scripts/create-dmg.sh [version]

set -e

VERSION=${1:-1.0.0}
APP_NAME="OzLand"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TEMP_DMG="temp.dmg"
VOLUME_NAME="$APP_NAME"

echo "Building $APP_NAME..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"
cp .build/release/$APP_NAME "$APP_NAME.app/Contents/MacOS/"

cp Info.plist "$APP_NAME.app/Contents/"

# Update Info.plist with bundle information
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$APP_NAME.app/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.ozland.app" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.ozland.app" "$APP_NAME.app/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$APP_NAME.app/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$APP_NAME.app/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$APP_NAME.app/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType APPL" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_NAME.app/Contents/Info.plist"

# Add icon if it exists
ICON_FILE=""
if [ -f "Assets/AppIcon.icns" ]; then
    ICON_FILE="Assets/AppIcon.icns"
elif [ -f "AppIcon.icns" ]; then
    ICON_FILE="AppIcon.icns"
elif [ -f "icon.icns" ]; then
    ICON_FILE="icon.icns"
fi

if [ -n "$ICON_FILE" ]; then
    echo "Adding icon: $ICON_FILE"
    cp "$ICON_FILE" "$APP_NAME.app/Contents/Resources/AppIcon.icns"
    ICON_NAME="AppIcon"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile $ICON_NAME" "$APP_NAME.app/Contents/Info.plist" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $ICON_NAME" "$APP_NAME.app/Contents/Info.plist"
else
    echo "⚠️  Warning: No icon file found. App will use default icon."
    echo "   Create an AppIcon.icns file in Assets/ or root directory to add an icon."
fi

echo "Creating DMG: $DMG_NAME"

# Create a temporary DMG with both app and Applications folder
mkdir -p "dmg-contents"
cp -R "$APP_NAME.app" "dmg-contents/"

# Create Applications symlink in dmg-contents
ln -s /Applications "dmg-contents/Applications"

# Create a temporary DMG
hdiutil create -srcfolder "dmg-contents" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 200m "$TEMP_DMG" 2>/dev/null

# Clean up dmg-contents
rm -rf "dmg-contents"

# Mount the DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')

# Wait for the mount to complete
sleep 2

# Ensure Applications symlink exists (backup in case it wasn't copied correctly)
VOLUME_PATH="/Volumes/$VOLUME_NAME"
if [ ! -L "$VOLUME_PATH/Applications" ]; then
    ln -s /Applications "$VOLUME_PATH/Applications" 2>/dev/null || true
fi

# Unmount the DMG
hdiutil detach "$DEVICE" 2>/dev/null || true

# Convert to final compressed DMG
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME" 2>/dev/null

# Remove temporary DMG
rm -f "$TEMP_DMG"

echo "✅ DMG created successfully: $DMG_NAME"


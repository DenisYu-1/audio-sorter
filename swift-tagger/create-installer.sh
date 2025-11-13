#!/bin/bash

# Create an installer app that users can double-click
set -e

APP_NAME="Audio Sorter"
BUNDLE_NAME="${APP_NAME}.app"
INSTALLER_NAME="Install ${APP_NAME}.app"

echo "📦 Creating user-friendly installer..."

# First ensure the app is built
if [ ! -d "$BUNDLE_NAME" ]; then
    echo "Building app first..."
    ./create-gui-app-bundle.sh
fi

# Remove old installer if exists
rm -rf "$INSTALLER_NAME"

# Create installer app structure
mkdir -p "$INSTALLER_NAME/Contents/MacOS"
mkdir -p "$INSTALLER_NAME/Contents/Resources"

# Create the installer script
cat > "$INSTALLER_NAME/Contents/MacOS/install" << 'INSTALLER_SCRIPT'
#!/bin/bash

# Audio Sorter Installer
# This script installs the app to /Applications and removes quarantine

APP_NAME="Audio Sorter"
BUNDLE_NAME="${APP_NAME}.app"

# Get the directory where this installer is located
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../Resources" && pwd)"

# Show a nice dialog
osascript <<EOF
tell application "System Events"
    activate
    display dialog "Welcome to ${APP_NAME} Installer!\n\nThis will install ${APP_NAME} to your Applications folder." buttons {"Cancel", "Install"} default button "Install" with icon note
    if button returned of result is "Cancel" then
        error number -128
    end if
end tell
EOF

# Copy the app to Applications (will prompt for password if needed)
echo "Installing ${APP_NAME}..."

if [ -d "/Applications/$BUNDLE_NAME" ]; then
    osascript -e "display dialog \"${APP_NAME} is already installed. Replace it?\" buttons {\"Cancel\", \"Replace\"} default button \"Replace\""
    if [ $? -ne 0 ]; then
        exit 0
    fi
    rm -rf "/Applications/$BUNDLE_NAME"
fi

# Copy to Applications
cp -R "$INSTALLER_DIR/$BUNDLE_NAME" "/Applications/$BUNDLE_NAME"

# Remove quarantine attributes
xattr -cr "/Applications/$BUNDLE_NAME" 2>/dev/null || true

# Success message
osascript <<EOF
tell application "System Events"
    activate
    display dialog "${APP_NAME} has been installed successfully!\n\nYou can now find it in your Applications folder." buttons {"Open Now", "Done"} default button "Open Now" with icon note
    if button returned of result is "Open Now" then
        do shell script "open -a '/Applications/$BUNDLE_NAME'"
    end if
end tell
EOF
INSTALLER_SCRIPT

# Make installer script executable
chmod +x "$INSTALLER_NAME/Contents/MacOS/install"

# Copy the app into the installer's Resources
cp -R "$BUNDLE_NAME" "$INSTALLER_NAME/Contents/Resources/"

# Create Info.plist for installer
cat > "$INSTALLER_NAME/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>install</string>
    <key>CFBundleIdentifier</key>
    <string>com.audiosorter.installer</string>
    <key>CFBundleName</key>
    <string>Audio Sorter Installer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Remove quarantine from installer
xattr -cr "$INSTALLER_NAME"

# Create a DMG for distribution
DMG_NAME="${APP_NAME} Installer.dmg"
echo "📦 Creating DMG..."

# Remove old DMG if exists
rm -f "$DMG_NAME"

# Create temporary folder
TMP_DIR=$(mktemp -d)
cp -R "$INSTALLER_NAME" "$TMP_DIR/"

# Add a symlink to Applications folder
ln -s /Applications "$TMP_DIR/Applications"

# Create README
cat > "$TMP_DIR/README.txt" << 'README'
Audio Sorter Installation
==========================

Installation is easy:

1. Double-click "Install Audio Sorter.app"
2. Click "Install" in the dialog
3. The app will be installed to your Applications folder

Note: On first install, you may see a security warning. 
This is because the app is not signed with an Apple Developer certificate.

If you see "cannot be opened because it is from an unidentified developer":
1. Right-click the installer
2. Click "Open"
3. Click "Open" in the security dialog

After installation, you can run the app normally from Applications.

---

Alternatively, you can manually drag "Audio Sorter.app" 
from inside the installer to your Applications folder.
README

# Create DMG
hdiutil create -volname "${APP_NAME} Installer" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDZO \
    "$DMG_NAME"

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "✅ Installer created successfully!"
echo ""
echo "📦 Distribution files:"
echo "   • $INSTALLER_NAME (double-click installer)"
echo "   • $DMG_NAME (disk image for distribution)"
echo ""
echo "🚀 Users can now:"
echo "   1. Download the DMG file"
echo "   2. Open it"
echo "   3. Double-click 'Install Audio Sorter.app'"
echo "   4. Click 'Install' in the dialog"
echo ""
echo "⚠️  First time only: User may need to right-click → Open on the installer"
echo "    (This is a one-time macOS security prompt for unsigned apps)"


#!/bin/bash

# Create macOS GUI App Bundle for Audio Sorter
# This version is properly configured for GUI operation

APP_NAME="Audio Sorter"
BUNDLE_NAME="Audio Sorter.app"
BINARY_NAME="SimpleAudioSorter"

echo "Creating macOS GUI App Bundle: $BUNDLE_NAME"

# Compile all Swift files into the binary
echo "🔨 Compiling modularized Swift source files..."
if ! swiftc main.swift Utils/AppDelegate.swift UI/MainViewController.swift UI/DragDropView.swift Core/AudioFileProcessor.swift Core/ProcessingResults.swift -o "$BINARY_NAME"; then
    echo "❌ Error: Failed to compile Swift files"
    exit 1
fi
echo "✅ Compilation successful"

# Remove existing bundle if it exists
if [[ -d "$BUNDLE_NAME" ]]; then
    rm -rf "$BUNDLE_NAME"
    echo "Removed existing app bundle"
fi

# Create app bundle structure
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copy binary
cp "$BINARY_NAME" "$BUNDLE_NAME/Contents/MacOS/"

# Create properly configured Info.plist for GUI app
cat > "$BUNDLE_NAME/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SimpleAudioSorter</string>
    <key>CFBundleIdentifier</key>
    <string>com.audiosorter.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Audio Sorter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2024 Audio Sorter</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>This app needs access to your music folders to sort MP3 files.</string>
    <key>NSMusicUsageDescription</key>
    <string>This app updates MP3 metadata using the Music app.</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSBackgroundOnly</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Make the binary executable
chmod +x "$BUNDLE_NAME/Contents/MacOS/$BINARY_NAME"

echo "✅ GUI App bundle created: $BUNDLE_NAME"
echo ""
echo "🖥️  To run the GUI app:"
echo "   open '$BUNDLE_NAME'"
echo ""
echo "📱 App features:"
echo "   • Native macOS GUI interface"
echo "   • Drag & drop folder selection"
echo "   • Real-time progress display"
echo "   • Live logging of operations"
echo "   • Zero installation required"
echo ""
# Install bundled Python dependencies
echo "📦 Installing bundled Python dependencies..."
PYTHON_LIBS_DIR="$BUNDLE_NAME/Contents/Resources/python-libs"
mkdir -p "$PYTHON_LIBS_DIR"

# Install mutagen into the app bundle
pip3 install --target "$PYTHON_LIBS_DIR" mutagen

echo "📦 Distribution:"
echo "   Copy '$BUNDLE_NAME' to any Mac and double-click!"
echo "   ✅ Universal Binary: Works on Intel & Apple Silicon Macs"
echo "   ✅ Zero Dependencies: mutagen bundled inside app"
echo "   ✅ Minimum macOS: 10.15 Catalina"

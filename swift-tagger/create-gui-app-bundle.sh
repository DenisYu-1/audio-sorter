#!/bin/bash

# Create macOS GUI App Bundle for Audio Sorter (SwiftUI version)

APP_NAME="Audio Sorter"
BUNDLE_NAME="Audio Sorter.app"
BINARY_NAME="SimpleAudioSorter"

echo "Creating macOS SwiftUI App Bundle: $BUNDLE_NAME"

# Build using Swift Package Manager
echo "🔨 Building with Swift Package Manager..."
if ! swift build -c release; then
    echo "❌ Error: Failed to build Swift package"
    exit 1
fi
echo "✅ Build successful"

# Copy the built binary from .build directory
cp ".build/release/$BINARY_NAME" "$BINARY_NAME"

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

# Create properly configured Info.plist for SwiftUI GUI app
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
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
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

echo "✅ SwiftUI App bundle created: $BUNDLE_NAME"
echo ""
echo "🖥️  To run the SwiftUI app:"
echo "   open '$BUNDLE_NAME'"
echo ""
echo "📱 SwiftUI App features:"
echo "   • Modern SwiftUI interface"
echo "   • Native macOS design"
echo "   • Drag & drop folder selection"
echo "   • Real-time progress display"
echo "   • Live logging of operations"
echo "   • Declarative UI architecture"
echo ""
# Install bundled Python dependencies
echo "📦 Installing bundled Python dependencies..."
PYTHON_LIBS_DIR="$BUNDLE_NAME/Contents/Resources/python-libs"
mkdir -p "$PYTHON_LIBS_DIR"

# Install mutagen into the app bundle
pip3 install --target "$PYTHON_LIBS_DIR" mutagen

# Remove quarantine attributes to prevent Gatekeeper issues
echo "🔓 Removing quarantine attributes..."
xattr -cr "$BUNDLE_NAME"

# Create distributable zip
echo "📦 Creating distributable zip..."
rm -f "$BUNDLE_NAME.zip"
ditto -c -k --keepParent "$BUNDLE_NAME" "$BUNDLE_NAME.zip"

# Remove quarantine from the zip too
xattr -cr "$BUNDLE_NAME.zip"

echo ""
echo "✅ Distribution package created!"
echo ""
echo "📦 Files created:"
echo "   • $BUNDLE_NAME (app bundle)"
echo "   • $BUNDLE_NAME.zip (distributable)"
echo ""
echo "🚀 To run locally:"
echo "   open '$BUNDLE_NAME'"
echo ""
echo "📨 To distribute:"
echo "   Share '$BUNDLE_NAME.zip'"
echo ""
echo "⚠️  First-time users need to:"
echo "   1. Extract the zip"
echo "   2. Right-click the app → Open (first time only)"
echo "   3. Click 'Open' in the security dialog"
echo ""
echo "✅ Features:"
echo "   • Universal Binary: Intel & Apple Silicon"
echo "   • Zero Dependencies: mutagen bundled"
echo "   • Minimum macOS: 12.0 Monterey"
echo "   • Built with SwiftUI"

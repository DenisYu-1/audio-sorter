#!/bin/bash

# Audio Sorter - Distribution Package Creator
# Creates a ready-to-share package of the Audio Sorter app

set -e

VERSION="1.0"
APP_NAME="Audio Sorter"
PACKAGE_NAME="AudioSorter-v${VERSION}"

echo "📦 Creating distribution package: ${PACKAGE_NAME}"

# Create distribution directory
DIST_DIR="dist"
PACKAGE_DIR="${DIST_DIR}/${PACKAGE_NAME}"

# Clean and create directories
rm -rf "$DIST_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📱 Copying app bundle..."
# Copy the app bundle
cp -R "swift-tagger/Audio Sorter.app" "$PACKAGE_DIR/"

echo "📚 Creating user documentation..."
# Create simplified README for end users
cat > "$PACKAGE_DIR/README.txt" << 'EOF'
🎵 Audio Sorter - Fix MP3 File Ordering

PERFECT FOR: Audiobooks for children's MP3 players

THE PROBLEM:
- Download audiobook: Chapter 1.mp3, Chapter 2.mp3, ..., Chapter 10.mp3
- Child's MP3 player plays: Chapter 1 → Chapter 10 → Chapter 11 → Chapter 2
- Story jumps around! Child gets confused!

THE SOLUTION:
1. Rename audiobook files to: 1.mp3, 2.mp3, 3.mp3, 10.mp3, 11.mp3
2. Double-click "Audio Sorter.app"
3. Drag your audiobook folder into the app window
4. Click "Sort Audio Files"
5. Files become: 001.mp3, 002.mp3, 003.mp3, 010.mp3, 011.mp3
6. Copy to child's MP3 player
7. Perfect story order! Happy child! 🎉

INSTALLATION:
- No installation needed!
- Just double-click "Audio Sorter.app"
- If macOS shows security warning, go to System Preferences → 
  Privacy & Security → Allow "Audio Sorter"

FEATURES:
✓ Zero-padding for perfect sorting
✓ Updates MP3 track numbers
✓ Drag & drop interface
✓ Real-time progress display
✓ Smart conflict resolution
✓ Works on any Mac

Created to help parents prepare audiobooks for children! 📚👨‍👩‍👧‍👦
EOF

echo "🛡️ Creating security note..."
# Create security instructions
cat > "$PACKAGE_DIR/SECURITY-INSTRUCTIONS.txt" << 'EOF'
🔐 macOS Security Instructions

When you first run Audio Sorter, macOS might show a warning:
"Audio Sorter cannot be opened because it is from an unidentified developer"

TO FIX THIS:
1. Right-click on "Audio Sorter.app"
2. Select "Open" from the menu
3. Click "Open" in the security dialog
4. The app will run normally from now on

ALTERNATIVE METHOD:
1. Go to System Preferences (System Settings on newer macOS)
2. Click "Privacy & Security"
3. Scroll down to "Security" section
4. Click "Allow Anyway" next to Audio Sorter message
5. Try opening the app again

WHY THIS HAPPENS:
- macOS protects users from unverified apps
- Audio Sorter is safe, but not code-signed with Apple Developer Account
- This is normal for small utilities and open-source apps

THE APP IS SAFE:
✓ No network access
✓ Only reads/writes MP3 files you choose
✓ Source code available on GitHub
✓ No data collection or tracking
EOF

echo "📋 Creating usage examples..."
# Create usage examples
cat > "$PACKAGE_DIR/EXAMPLES.txt" << 'EOF'
📚 Audio Sorter Usage Examples

EXAMPLE 1: AUDIOBOOK CHAPTERS
Before: Chapter 1.mp3, Chapter 2.mp3, ..., Chapter 10.mp3, Chapter 11.mp3
Rename to: 1.mp3, 2.mp3, ..., 10.mp3, 11.mp3
After processing: 001.mp3, 002.mp3, ..., 010.mp3, 011.mp3

EXAMPLE 2: MUSIC ALBUM
Before: 1.mp3, 2.mp3, 3.mp3, 10.mp3, 11.mp3, 12.mp3
After processing: 01.mp3, 02.mp3, 03.mp3, 10.mp3, 11.mp3, 12.mp3

EXAMPLE 3: LARGE AUDIOBOOK SERIES
Before: 1.mp3, 2.mp3, ..., 99.mp3, 100.mp3
After processing: 001.mp3, 002.mp3, ..., 099.mp3, 100.mp3

STEP-BY-STEP GUIDE:
1. Download your audiobook from store
2. Rename files to simple numbers: 1.mp3, 2.mp3, 3.mp3, etc.
   (Remove "Chapter" or other text, keep just numbers)
3. Put all files in one folder
4. Double-click Audio Sorter.app
5. Drag the folder into the app window
6. Click "Sort Audio Files"
7. Watch the progress as files are renamed
8. Copy the sorted files to your child's MP3 player
9. Enjoy perfect playback order!

SUPPORTED FORMATS:
- Only processes files named with numbers: 1.mp3, 2.mp3, etc.
- Ignores files like "intro.mp3" or "Track 1.mp3"
- Files must be MP3 format
- Works with any number range (1-999+)

BEFORE USING:
- Make a backup of your files (just in case!)
- Ensure files are named as numbers only: 1.mp3, 2.mp3, etc.
- All files should be in the same folder
EOF

echo "📄 Creating changelog..."
# Create changelog
cat > "$PACKAGE_DIR/CHANGELOG.txt" << 'EOF'
📅 Audio Sorter Changelog

Version 1.0 (2024)
✅ Initial release
✅ Native macOS GUI application
✅ Drag & drop folder selection
✅ Zero-padding for file names (1.mp3 → 001.mp3)
✅ ID3 tag updates via Music app integration
✅ Real-time progress display
✅ Smart conflict resolution (overwrites for consistency)
✅ No installation required
✅ No external dependencies
✅ Perfect for audiobooks and children's MP3 players

Created specifically to solve audiobook ordering problems
for parents preparing content for children's audio devices! 📚👨‍👩‍👧‍👦
EOF

echo "📦 Creating ZIP package..."
# Create ZIP file
cd "$DIST_DIR"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME"
cd ..

echo "✅ Distribution package created!"
echo ""
echo "📂 Package location: ${DIST_DIR}/${PACKAGE_NAME}.zip"
echo "📱 App bundle: ${PACKAGE_DIR}/Audio Sorter.app"
echo "📚 Documentation: ${PACKAGE_DIR}/README.txt"
echo ""
echo "🚀 Ready to share! Options:"
echo "   • Upload ${PACKAGE_NAME}.zip to GitHub releases"
echo "   • Share via email, cloud storage, or USB drive" 
echo "   • Perfect for helping other parents with audiobook chaos!"
echo ""
echo "📋 Package contents:"
ls -la "$PACKAGE_DIR"



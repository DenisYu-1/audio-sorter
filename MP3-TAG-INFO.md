# MP3 Tag Information & Track Number Updates

## What Are MP3 Tags?

MP3 tags are **standardized metadata** stored inside MP3 files that contain information like:
- **Track Number** (TRCK field)
- Title, Artist, Album
- Genre, Year, etc.

## Track Number Standard

The **track number** is stored in the **ID3 tag standard**:

### ID3v1 Tags
- **Track field**: Single byte (0-255)
- Limited but universally supported

### ID3v2 Tags  
- **TRCK frame**: Text frame
- Can store formats like:
  - `"1"` (simple number)
  - `"01"` (zero-padded)
  - `"1/12"` (track 1 of 12 total)

## How Audio Sorter Updates Tags

### What Gets Updated
1. **Filename**: `1.mp3` → `001.mp3`
2. **Track Number Tag**: Set to `1` (numeric value)
3. **Title Tag** (optional): Set to `"Track 1"` if title is missing or just a number

### Example Transformation
```
File: 1.mp3
├─ Filename: 1.mp3 → 001.mp3
├─ Track Number: (none) → 1
└─ Title: "1" → "Track 1"

File: 25.mp3  
├─ Filename: 25.mp3 → 025.mp3
├─ Track Number: (none) → 25
└─ Title: (unchanged if meaningful)
```

## MP3 Player Compatibility

### ✅ **Players That Use Track Numbers**
- **Apple Music/iTunes**: Sorts by track number
- **Spotify**: Respects track order
- **VLC**: Can sort by track number
- **Most modern players**: Use metadata for sorting

### ⚠️ **Players That Use Filenames**
- **Older car stereos**: May still use filename sorting
- **Basic MP3 players**: Often filename-based
- **File browsers**: Always use filename sorting

## Dependencies

### Required for Tag Updates
- **Python 3** (built into macOS)
- **Mutagen library**: **Automatically bundled** with the app

### Self-Contained Design
The app includes a bundled version of `mutagen` library:
- ✅ **No installation required** - everything is included
- ✅ **Consistent behavior** - same version on all systems
- ✅ **Offline operation** - no internet required
- ✅ **Version controlled** - no dependency conflicts

### Error Handling
- Uses **bundled mutagen library only** (no system dependencies)
- If bundled library missing, **filename renaming still works**
- App shows clear error messages and rebuild instructions
- GUI provides detailed feedback about operations

## Usage

### GUI Application (Recommended)
```bash
# Open the app
open "swift-tagger/Audio Sorter.app"

# Then drag your music folder into the app window
# and click "Sort Audio Files"
```

### Manual Build & Run
```bash
cd swift-tagger
swiftc SimpleAudioSorter.swift -o SimpleAudioSorter
./create-gui-app-bundle.sh
open "Audio Sorter.app"
```

## Technical Details

### Tag Reading/Writing
- Uses **Mutagen library** (Python)
- Preserves existing tags
- Only updates track number and title (if needed)
- Safe: Creates backup of tag data internally

### Error Handling
- **Non-destructive**: File renaming happens first
- **Graceful degradation**: Script succeeds even if tags fail
- **Clear feedback**: Shows exactly what succeeded/failed

### File Format Support
- **MP3 files only**: ID3v1 and ID3v2 tags
- **Other formats**: Not processed (safely ignored)

## Why Both Filename AND Tags?

### Filename Renaming
- **Universal compatibility**: Works on ANY device
- **Immediate effect**: No tag reading required
- **File browser sorting**: Works everywhere

### Tag Updates  
- **Professional metadata**: Proper music library management
- **Music app integration**: Better experience in iTunes, Spotify, etc.
- **Future-proofing**: Modern players prefer metadata

### Best of Both Worlds
✅ **Old devices**: Use filename sorting (001.mp3, 002.mp3...)  
✅ **Modern apps**: Use track number metadata (1, 2, 3...)  
✅ **File browsers**: Sorted correctly everywhere  

## Verification

### Check Tag Updates Worked
```bash
# Install id3v2 tool (optional)
brew install id3v2

# View tags
id3v2 -l 001.mp3

# Or use Python
python3 -c "
from mutagen.mp3 import MP3
audio = MP3('001.mp3')
print('Track:', audio.tags.get('TRCK'))
print('Title:', audio.tags.get('TIT2'))
"
```

### In Music Apps
1. **iTunes/Music**: Import folder and check track order
2. **VLC**: Open folder and verify playlist order
3. **Any music app**: Should show proper track numbers

## Troubleshooting

### "Mutagen not found"
```bash
# Manual installation
pip3 install mutagen

# Or use Homebrew Python
brew install python
/usr/local/bin/pip3 install mutagen
```

### "Permission denied" 
```bash
# Make sure you own the MP3 files
chmod 644 *.mp3

# Or run with sudo (not recommended)
open "swift-tagger/Audio Sorter.app"
# Drag your music folder into the app
```

### Tags not visible in player
- Some players cache metadata
- Try refreshing/rescanning library
- Older players may not support ID3v2

## Alternative Tools

If you prefer other tag editing tools:

### Command Line Tools
```bash
# Install via Homebrew
brew install id3v2

# Update track number
id3v2 -T 1 001.mp3
```

### GUI Applications
- **MP3Tag** (Windows/Mac)
- **Kid3** (Cross-platform)
- **MusicBrainz Picard** (Advanced tagging)

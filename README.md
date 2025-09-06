# 🎵 Audio Sorter

**Fix MP3 file sorting problems with intelligent filename normalization**

## 🚀 **The Problem**

Children's MP3 players and basic audio devices sort files lexicographically, causing chaos with audiobook chapters and numbered content:

### **📚 Audiobook Example:**
```
❌ Wrong order: Chapter 1.mp3 → Chapter 10.mp3 → Chapter 11.mp3 → Chapter 2.mp3
✅ Right order: Chapter 001.mp3 → Chapter 002.mp3 → Chapter 010.mp3 → Chapter 011.mp3
```

### **🎵 Music Example:**
```
❌ Bad sorting: 1.mp3, 10.mp3, 11.mp3, 2.mp3, 3.mp3, 100.mp3
✅ Good sorting: 001.mp3, 002.mp3, 003.mp3, 010.mp3, 011.mp3, 100.mp3
```

**Perfect for:** Audiobooks, children's stories, educational content, music albums

## 🎯 **The Solution**

Audio Sorter automatically renames your MP3 files with proper zero-padding and updates ID3 track metadata for perfect sorting on any audio player.

## 📱 **Native macOS GUI App**

### **🖱️ Super Easy to Use:**
1. **Double-click** `Audio Sorter.app`
2. **Drag & drop** your music folder into the window
3. **Click "Sort Audio Files"**
4. **Done!** Perfect file ordering guaranteed

### **✨ Features:**
- ✅ **Zero-padding** - Converts `1.mp3` → `001.mp3`
- ✅ **Updates MP3 track numbers** using Music app integration
- ✅ **Smart conflict resolution** - Fixes filename conflicts automatically
- ✅ **Drag & drop interface** - No typing required
- ✅ **Real-time progress** - See exactly what's happening
- ✅ **Zero installation** - No dependencies or setup needed

### **📱 App Location:**
```bash
swift-tagger/Audio Sorter.app
```

### **🚀 Run the App:**
```bash
open "swift-tagger/Audio Sorter.app"
```

### **📦 Distribution:**
Simply copy `Audio Sorter.app` to any Mac and double-click! No installation required.

---

## 🛠️ **For Developers**

### **📂 Project Structure:**
```
audio-sorter/
├── swift-tagger/
│   ├── Audio Sorter.app/          # ← Ready-to-use GUI app
│   ├── SimpleAudioSorter.swift    # ← Source code
│   ├── create-gui-app-bundle.sh   # ← Build script
│   └── README.md                  # ← Technical details
├── test-audio-sorter.sh           # ← Test suite
├── sort-audio.sh                  # ← CLI version (optional)
└── MP3-TAG-INFO.md               # ← Technical documentation
```

### **🔧 Rebuild the App:**
```bash
cd swift-tagger
swiftc SimpleAudioSorter.swift -o SimpleAudioSorter
./create-gui-app-bundle.sh
```

### **🧪 Test with Sample Files:**
```bash
./test-audio-sorter.sh create    # Create test MP3 files
./test-audio-sorter.sh cleanup   # Clean up test files
```

---

## 🎵 **How It Works**

### **📁 Before Processing:**
```
Your Music Folder/
├── 1.mp3          ← Track 1
├── 2.mp3          ← Track 2  
├── 10.mp3         ← Track 10
├── 11.mp3         ← Track 11
└── 100.mp3        ← Track 100
```

### **📱 Audio Player Sees (WRONG ORDER):**
```
1.mp3 → 10.mp3 → 100.mp3 → 11.mp3 → 2.mp3
```

### **📁 After Processing:**
```
Your Music Folder/
├── 001.mp3        ← Track 1 (ID3: track 1)
├── 002.mp3        ← Track 2 (ID3: track 2)
├── 010.mp3        ← Track 10 (ID3: track 10)
├── 011.mp3        ← Track 11 (ID3: track 11)
└── 100.mp3        ← Track 100 (ID3: track 100)
```

### **📱 Audio Player Sees (PERFECT ORDER):**
```
001.mp3 → 002.mp3 → 010.mp3 → 011.mp3 → 100.mp3
```

---

## 📚 **Perfect for Audiobooks**

### **🎯 Common Scenario:**
Your wife downloads an audiobook for your child's MP3 player. The store provides files like:
```
Chapter 1.mp3, Chapter 2.mp3, ..., Chapter 10.mp3, Chapter 11.mp3
```

### **😱 Problem:**
Child's MP3 player plays them as:
```
Chapter 1.mp3 → Chapter 10.mp3 → Chapter 11.mp3 → Chapter 2.mp3 → Chapter 3.mp3...
```
**Story jumps around! Child gets confused! 😢**

### **✨ Solution:**
Audio Sorter fixes it automatically:
```
Chapter 001.mp3 → Chapter 002.mp3 → Chapter 003.mp3 → Chapter 010.mp3 → Chapter 011.mp3...
```
**Perfect story order! Happy child! 🎉**

### **🚀 How to Use:**
1. **Download audiobook** from store
2. **Rename files** to simple numbers: `1.mp3, 2.mp3, 3.mp3...` 
3. **Drag folder** into Audio Sorter app
4. **Click "Sort Audio Files"**
5. **Copy to child's MP3 player**
6. **Enjoy perfect playback order!** 🎵

---

## 🔧 **Command Line Option**

For advanced users who prefer command-line usage:

```bash
./sort-audio.sh "/path/to/music/folder"
```

### **CLI Features:**
- Dry-run mode: `./sort-audio.sh "/path" true`
- Skip tags: `./sort-audio.sh "/path" false false`

---

## ⚙️ **Technical Details**

### **🎛️ ID3 Tag Updates:**
- Uses **AppleScript** + **Music app** integration
- Updates **TRCK** (track number) field
- **Zero dependencies** - uses built-in macOS tools
- **Safe & reliable** - leverages Music app's robust tag handling

### **📋 File Handling:**
- **Smart padding** - automatically detects required digit count
- **Conflict resolution** - replaces inconsistent naming with normalized format
- **Preserves original files** - only renames, doesn't alter audio content
- **Fast processing** - handles large music collections efficiently

### **🔒 Safety Features:**
- **Transparent logging** - see exactly what files are processed
- **Non-destructive** - only changes filenames and metadata
- **Rollback friendly** - easy to undo if needed

---

## 🆘 **Troubleshooting**

### **🚫 App won't open?**
Try: `chmod +x "swift-tagger/Audio Sorter.app/Contents/MacOS/SimpleAudioSorter"`

### **🎵 Music app permission issues?**
1. Open **System Preferences** → **Privacy & Security**
2. Allow **Audio Sorter** to control **Music app**

### **📁 Files not found?**
- Only processes files matching pattern: `1.mp3`, `2.mp3`, etc.
- Files like `Track 1.mp3` or `song.mp3` are ignored
- Use numbered files only: `1.mp3`, `2.mp3`, `10.mp3`

---

## 🎉 **Result**

**Perfect audio file organization with just a few clicks!** 

Your MP3 player will finally play your tracks in the correct order, every time. 🎵✨

---

## 📜 **About**

Originally created to help parents prepare audiobooks for children's MP3 players. Many audiobook stores provide files with inconsistent numbering that causes playback chaos on basic audio devices.

**Now every story plays in perfect order!** 📚✨

## 📜 **License**

Created for families who want their audiobooks and music to play in the right order! 🎶👨‍👩‍👧‍👦

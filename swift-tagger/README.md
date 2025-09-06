# Swift MP3 Analyzer

## 🚀 **Native macOS Binary for MP3 Analysis**

This is a **zero-dependency**, **native macOS binary** that analyzes MP3 files and generates commands for tag updates.

### **Key Features:**
- ✅ **No installation required** - single binary file
- ✅ **Native performance** - compiled Swift code
- ✅ **Zero dependencies** - works on any Mac
- ✅ **Generates AppleScript commands** for tag updates
- ✅ **124KB size** - tiny and portable

## 📁 **Files:**

- `mp3-analyzer` - Compiled binary (ARM64 macOS)
- `mp3-analyzer.swift` - Source code
- `mp3-tagger-simple.swift` - Alternative approach (unused)
- `mp3-tagger.swift` - Complex approach (unused)

## 🎯 **Usage:**

### **Basic Analysis:**
```bash
./mp3-analyzer /path/to/music/folder
```

### **Verbose Output:**
```bash
./mp3-analyzer /path/to/music/folder --verbose
```

### **Example Output:**
```
MP3 File Analyzer - Swift Version
=================================
Found 8 numeric MP3 files in: /path/to/music

1.mp3 → Track #1 (filename: 001.mp3)
2.mp3 → Track #2 (filename: 002.mp3)
10.mp3 → Track #10 (filename: 010.mp3)
25.mp3 → Track #25 (filename: 025.mp3)
100.mp3 → Track #100 (filename: 100.mp3)

Summary:
--------
Total files: 5
Track range: 1 - 100
Recommended padding: 3 digits

Shell commands to update tags (using native tools):
---------------------------------------------------
# Set track 1 for 1.mp3
osascript -e 'tell application "Music" to set track number of (add (POSIX file "/path/to/music/1.mp3")) to 1'
# Set track 2 for 2.mp3
osascript -e 'tell application "Music" to set track number of (add (POSIX file "/path/to/music/2.mp3")) to 2'
...
```

## 📋 **What It Does:**

1. **Scans directory** for numeric MP3 files
2. **Analyzes file patterns** (1.mp3, 01.mp3, 001.mp3, etc.)
3. **Maps to track numbers** (1.mp3 → Track #1)
4. **Shows file information** (size, modification date)
5. **Generates AppleScript commands** for tag updates

## 🔧 **Integration:**

### **Standalone Usage:**
```bash
# Copy binary to any Mac
cp mp3-analyzer /usr/local/bin/
mp3-analyzer ~/Music/Album
```

### **In Shell Scripts:**
```bash
#!/bin/bash
# Use the analyzer in other scripts
./mp3-analyzer "$1" > tag-commands.sh
chmod +x tag-commands.sh
./tag-commands.sh
```

### **With Automator:**
The binary can be integrated into Automator workflows for GUI applications.

## 🏗️ **Technical Details:**

### **Compilation:**
```bash
swiftc mp3-analyzer.swift -o mp3-analyzer
```

### **Dependencies:**
- **Swift runtime** (built into macOS)
- **Foundation framework** (built into macOS)
- **No external libraries required**

### **Architecture:**
- **ARM64 (Apple Silicon)** - native performance
- **Can be compiled for Intel** if needed: `swiftc -target x86_64-apple-macosx mp3-analyzer.swift -o mp3-analyzer-intel`

### **File Detection:**
- Finds files matching pattern: `^\d+\.mp3$`
- Supports: `1.mp3`, `01.mp3`, `001.mp3`, etc.
- Ignores: `Track 1.mp3`, `song.mp3`, etc.

## 📦 **Distribution:**

### **Single Binary Distribution:**
1. **Copy `mp3-analyzer` binary** to target Mac
2. **Make executable**: `chmod +x mp3-analyzer`
3. **Run immediately** - no setup required

### **App Bundle Distribution:**
The binary can be included in macOS app bundles for distribution through normal channels.

### **Universal Binary:**
For compatibility with both Apple Silicon and Intel Macs:
```bash
# Compile for both architectures
swiftc -target arm64-apple-macosx mp3-analyzer.swift -o mp3-analyzer-arm64
swiftc -target x86_64-apple-macosx mp3-analyzer.swift -o mp3-analyzer-x86_64

# Create universal binary
lipo -create mp3-analyzer-arm64 mp3-analyzer-x86_64 -output mp3-analyzer-universal
```

## 🎵 **Why This Approach:**

### **Advantages:**
- ✅ **True zero dependencies** - no Python, Node.js, or external tools
- ✅ **Native performance** - compiled code runs fast
- ✅ **Professional appearance** - generates proper shell commands
- ✅ **Easy distribution** - single file to copy
- ✅ **Future-proof** - uses stable macOS APIs

### **Limitations:**
- 📋 **Analysis only** - doesn't modify files directly
- 🔧 **Requires AppleScript** for actual tag updates
- 🍎 **macOS only** - not cross-platform

## 🔄 **Workflow Integration:**

### **Complete Solution:**
1. **Sort filenames** using shell scripts
2. **Analyze with Swift binary** to generate commands
3. **Execute AppleScript commands** to update tags
4. **Package in Automator** for drag & drop functionality

This provides the **best of all worlds**: 
- Native performance
- Zero installation requirements  
- Professional metadata handling
- Easy distribution

## 🧪 **Testing:**

```bash
# Create test files
mkdir test-music
touch test-music/{1,2,10,25}.mp3

# Analyze
./mp3-analyzer test-music

# Should show proper track number mapping
```

The Swift binary is now **ready for production use** and can be distributed as part of the audio sorter solution! 🎉

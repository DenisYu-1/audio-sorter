#!/usr/bin/env python3

import os
import sys
import re
from pathlib import Path

def ensure_mutagen():
    """Load ONLY the bundled mutagen library (no system fallback)."""
    # Find the bundled mutagen library
    script_dir = os.path.dirname(os.path.abspath(__file__))
    bundled_libs = os.path.join(script_dir, "Audio Sorter.app", "Contents", "Resources", "python-libs")
    
    if not os.path.exists(bundled_libs):
        print("Error: Bundled mutagen library not found.")
        print(f"Expected location: {bundled_libs}")
        print("The app bundle may be corrupted or incomplete.")
        print("Please rebuild the app with: ./create-gui-app-bundle.sh")
        return False
    
    # Clear any existing paths and use ONLY the bundled version
    # Remove any existing mutagen imports
    modules_to_remove = [module for module in sys.modules if module.startswith('mutagen')]
    for module in modules_to_remove:
        del sys.modules[module]
    
    # Add bundled libs to the BEGINNING of the path (highest priority)
    if bundled_libs in sys.path:
        sys.path.remove(bundled_libs)
    sys.path.insert(0, bundled_libs)
    
    try:
        import mutagen.mp3
        print(f"✓ Using bundled mutagen from: {bundled_libs}")
        return True
    except ImportError as e:
        print(f"Error: Failed to load bundled mutagen library: {e}")
        print(f"Bundled libs directory exists but import failed.")
        print("The app bundle may be corrupted.")
        return False

def update_mp3_tags(directory_path):
    """Update MP3 track numbers based on filename."""
    if not ensure_mutagen():
        print("Error: Cannot install mutagen library")
        return False
    
    from mutagen.mp3 import MP3
    from mutagen.id3 import ID3NoHeaderError, TRCK, TIT2
    
    if not os.path.isdir(directory_path):
        print(f"Error: Directory not found: {directory_path}")
        return False
    
    # Find numeric MP3 files
    mp3_files = []
    for file_path in Path(directory_path).glob("*.mp3"):
        filename = file_path.name
        match = re.match(r'^(\d+)\.mp3$', filename)
        if match:
            track_num = int(match.group(1))
            mp3_files.append((str(file_path), track_num, filename))
    
    if not mp3_files:
        print("No numeric MP3 files found")
        return True
    
    # Update tags
    success_count = 0
    for file_path, track_num, filename in mp3_files:
        try:
            # Load MP3 file
            audio = MP3(file_path)
            
            # Add ID3 tag if it doesn't exist
            if audio.tags is None:
                audio.add_tags()
            
            # Set track number
            audio.tags['TRCK'] = TRCK(encoding=3, text=str(track_num))
            
            # Set title if it's just a number
            current_title = str(audio.tags.get('TIT2', ''))
            if not current_title or current_title.isdigit():
                audio.tags['TIT2'] = TIT2(encoding=3, text=f"Track {track_num}")
            
            # Save changes
            audio.save()
            print(f"✓ Updated {filename}: Track {track_num}")
            success_count += 1
            
        except Exception as e:
            print(f"✗ Failed to update {filename}: {e}")
    
    print(f"Successfully updated {success_count}/{len(mp3_files)} files")
    return success_count > 0

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 update-mp3-tags.py <directory>")
        sys.exit(1)
    
    directory = sys.argv[1]
    success = update_mp3_tags(directory)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

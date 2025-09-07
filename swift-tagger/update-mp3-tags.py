#!/usr/bin/env python3

import os
import sys
import argparse
import struct
from pathlib import Path

class SimpleID3Writer:
    """Simple ID3 tag writer without external dependencies."""
    
    def __init__(self):
        self.id3v1_genres = [
            "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge",
            "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
            "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska",
            "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient",
            "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical",
            "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise",
            "Alternative Rock", "Bass", "Soul", "Punk", "Space", "Meditative",
            "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave",
            "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream",
            "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap",
            "Pop/Funk", "Jungle", "Native US", "Cabaret", "New Wave", "Psychadelic",
            "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk",
            "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock"
        ]
    
    def write_id3v1(self, file_path, title=None, artist=None, album=None, year=None, 
                    comment=None, track_number=None, genre=None):
        """Write ID3v1 tag (simple, 128 bytes at end of file)."""
        try:
            with open(file_path, 'r+b') as f:
                # Go to end of file
                f.seek(0, 2)
                file_size = f.tell()
                
                # Check if ID3v1 tag already exists
                if file_size >= 128:
                    f.seek(-128, 2)
                    existing_tag = f.read(3)
                    if existing_tag == b'TAG':
                        # Overwrite existing tag
                        f.seek(-128, 2)
                    else:
                        # Append new tag
                        f.seek(0, 2)
                else:
                    f.seek(0, 2)
                
                # Create ID3v1 tag (128 bytes total)
                tag = bytearray(128)
                tag[0:3] = b'TAG'  # Header
                
                # Title (30 bytes)
                if title:
                    title_bytes = title.encode('latin1', errors='ignore')[:30]
                    tag[3:3+len(title_bytes)] = title_bytes
                
                # Artist (30 bytes)
                if artist:
                    artist_bytes = artist.encode('latin1', errors='ignore')[:30]
                    tag[33:33+len(artist_bytes)] = artist_bytes
                
                # Album (30 bytes)  
                if album:
                    album_bytes = album.encode('latin1', errors='ignore')[:30]
                    tag[63:63+len(album_bytes)] = album_bytes
                
                # Year (4 bytes)
                if year:
                    year_str = str(year)[:4]
                    year_bytes = year_str.encode('latin1', errors='ignore')
                    tag[93:93+len(year_bytes)] = year_bytes
                
                # Comment (28 bytes for ID3v1.1, 30 for ID3v1.0)
                comment_end = 125
                if track_number is not None:
                    # ID3v1.1 format - track number in byte 126
                    comment_end = 123
                    tag[125] = 0  # Zero byte separator
                    tag[126] = track_number & 0xFF
                
                if comment:
                    comment_bytes = comment.encode('latin1', errors='ignore')[:comment_end-97]
                    tag[97:97+len(comment_bytes)] = comment_bytes
                
                # Genre (1 byte)
                genre_byte = 255  # Unknown genre
                if genre is not None:
                    if isinstance(genre, int) and 0 <= genre < len(self.id3v1_genres):
                        genre_byte = genre
                    elif isinstance(genre, str):
                        try:
                            genre_idx = self.id3v1_genres.index(genre)
                            genre_byte = genre_idx
                        except ValueError:
                            pass
                tag[127] = genre_byte
                
                f.write(tag)
                return True, "ID3v1 tag written successfully"
        except Exception as e:
            return False, f"Error writing ID3v1 tag: {e}"
    
    def write_id3v2_simple(self, file_path, track_number, title=None, album=None):
        """Write ID3v2.3 tag preserving existing frames, updating only specified ones."""
        try:
            with open(file_path, 'rb') as f:
                data = f.read()
            
            existing_frames = []
            id3v2_size = 0
            mp3_data = data
            
            # Parse existing ID3v2 tag if present
            if data.startswith(b'ID3') and len(data) >= 10:
                size_bytes = data[6:10]
                # ID3v2 size is synchsafe integer
                id3v2_size = (size_bytes[0] << 21) | (size_bytes[1] << 14) | (size_bytes[2] << 7) | size_bytes[3]
                id3v2_size += 10  # Header size
                
                # Extract MP3 data without ID3v2 tag
                mp3_data = data[id3v2_size:]
                
                # Parse existing frames to preserve them
                existing_frames = self._parse_existing_frames(data[10:id3v2_size])
            else:
                # No existing ID3v2 tag
                mp3_data = data
            
            # Filter out frames we want to replace
            frames_to_update = {'TRCK', 'TIT2', 'TALB'}
            preserved_frames = [frame for frame in existing_frames 
                               if not frame.startswith(tuple(f.encode('ascii') for f in frames_to_update))]
            
            # Add our new/updated frames
            new_frames = []
            
            # Track number frame (TRCK)
            if track_number is not None:
                track_str = str(track_number)
                track_frame = self._create_text_frame('TRCK', track_str)
                new_frames.append(track_frame)
            
            # Title frame (TIT2) - only if explicitly provided
            if title:
                title_frame = self._create_text_frame('TIT2', title)
                new_frames.append(title_frame)
            
            # Album frame (TALB)
            if album:
                album_frame = self._create_text_frame('TALB', album)
                new_frames.append(album_frame)
            
            # Combine preserved and new frames
            all_frames_data = b''.join(preserved_frames + new_frames)
            frames_size = len(all_frames_data)
            
            # Create ID3v2 header
            header = bytearray(10)
            header[0:3] = b'ID3'  # Identifier
            header[3] = 3         # Major version (ID3v2.3)
            header[4] = 0         # Revision
            header[5] = 0         # Flags
            
            # Size (synchsafe integer)
            header[6] = (frames_size >> 21) & 0x7F
            header[7] = (frames_size >> 14) & 0x7F
            header[8] = (frames_size >> 7) & 0x7F
            header[9] = frames_size & 0x7F
            
            # Write new file
            with open(file_path, 'wb') as f:
                f.write(header)
                f.write(all_frames_data)
                f.write(mp3_data)
            
            return True, "ID3v2 tag updated (existing frames preserved)"
        except Exception as e:
            return False, f"Error updating ID3v2 tag: {e}"
    
    def _parse_existing_frames(self, frames_data):
        """Parse existing ID3v2 frames to preserve them."""
        frames = []
        offset = 0
        
        while offset + 10 < len(frames_data):
            # Check for padding (all zeros)
            if frames_data[offset:offset+4] == b'\x00\x00\x00\x00':
                break
            
            # Frame header: 4 bytes ID + 4 bytes size + 2 bytes flags
            frame_id = frames_data[offset:offset+4]
            
            # Skip invalid frame IDs
            if not all(32 <= b <= 126 for b in frame_id):
                break
                
            size_bytes = frames_data[offset+4:offset+8]
            frame_size = (size_bytes[0] << 24) | (size_bytes[1] << 16) | (size_bytes[2] << 8) | size_bytes[3]
            
            # Validate frame size
            if frame_size <= 0 or offset + 10 + frame_size > len(frames_data):
                break
            
            # Extract complete frame (header + data)
            complete_frame = frames_data[offset:offset+10+frame_size]
            frames.append(complete_frame)
            
            offset += 10 + frame_size
        
        return frames
    
    def _create_text_frame(self, frame_id, text):
        """Create a text frame for ID3v2."""
        text_data = text.encode('utf-8')
        frame_size = 1 + len(text_data)  # 1 byte for encoding + text
        
        frame = bytearray(10 + frame_size)  # 10 byte header + data
        frame[0:4] = frame_id.encode('ascii')
        
        # Frame size (big endian, not synchsafe for ID3v2.3)
        frame[4] = (frame_size >> 24) & 0xFF
        frame[5] = (frame_size >> 16) & 0xFF
        frame[6] = (frame_size >> 8) & 0xFF
        frame[7] = frame_size & 0xFF
        
        # Flags (2 bytes)
        frame[8] = 0
        frame[9] = 0
        
        # Data
        frame[10] = 3  # UTF-8 encoding
        frame[11:] = text_data
        
        return bytes(frame)
    
    def read_existing_tags(self, file_path):
        """Read existing ID3 tags from MP3 file."""
        try:
            with open(file_path, 'rb') as f:
                data = f.read()
            
            tags = {
                'track_number': None,
                'title': None,
                'album': None,
                'artist': None
            }
            
            # Try to read ID3v2 tag first
            if data.startswith(b'ID3') and len(data) >= 10:
                size_bytes = data[6:10]
                id3v2_size = (size_bytes[0] << 21) | (size_bytes[1] << 14) | (size_bytes[2] << 7) | size_bytes[3]
                id3v2_size += 10
                
                frames_data = data[10:id3v2_size]
                tags.update(self._parse_tag_values(frames_data))
            
            # Fallback to ID3v1 if no ID3v2 or incomplete data
            if not any(tags.values()) and len(data) >= 128:
                if data[-128:-125] == b'TAG':
                    id3v1_data = data[-128:]
                    tags.update(self._parse_id3v1_values(id3v1_data))
            
            return tags
        except Exception as e:
            return {'error': str(e)}
    
    def _parse_tag_values(self, frames_data):
        """Parse ID3v2 frame values."""
        tags = {}
        offset = 0
        
        while offset + 10 < len(frames_data):
            if frames_data[offset:offset+4] == b'\x00\x00\x00\x00':
                break
            
            frame_id = frames_data[offset:offset+4]
            if not all(32 <= b <= 126 for b in frame_id):
                break
                
            size_bytes = frames_data[offset+4:offset+8]
            frame_size = (size_bytes[0] << 24) | (size_bytes[1] << 16) | (size_bytes[2] << 8) | size_bytes[3]
            
            if frame_size <= 0 or offset + 10 + frame_size > len(frames_data):
                break
            
            frame_data = frames_data[offset+10:offset+10+frame_size]
            frame_id_str = frame_id.decode('ascii', errors='ignore')
            
            # Parse text frames
            if frame_id_str in ['TRCK', 'TIT2', 'TALB', 'TPE1'] and len(frame_data) > 0:
                # Skip encoding byte
                text_data = frame_data[1:] if len(frame_data) > 1 else b''
                try:
                    if frame_data[0] == 3:  # UTF-8
                        text = text_data.decode('utf-8', errors='ignore').strip('\x00')
                    else:  # Latin-1 or other
                        text = text_data.decode('latin-1', errors='ignore').strip('\x00')
                    
                    if frame_id_str == 'TRCK':
                        # Extract just the track number (before any '/')
                        track_str = text.split('/')[0].strip()
                        try:
                            tags['track_number'] = int(track_str)
                        except ValueError:
                            pass
                    elif frame_id_str == 'TIT2':
                        tags['title'] = text
                    elif frame_id_str == 'TALB':
                        tags['album'] = text
                    elif frame_id_str == 'TPE1':
                        tags['artist'] = text
                except:
                    pass
            
            offset += 10 + frame_size
        
        return tags
    
    def _parse_id3v1_values(self, id3v1_data):
        """Parse ID3v1 tag values."""
        tags = {}
        try:
            title = id3v1_data[3:33].decode('latin-1', errors='ignore').strip('\x00').strip()
            artist = id3v1_data[33:63].decode('latin-1', errors='ignore').strip('\x00').strip()
            album = id3v1_data[63:93].decode('latin-1', errors='ignore').strip('\x00').strip()
            
            if title:
                tags['title'] = title
            if artist:
                tags['artist'] = artist
            if album:
                tags['album'] = album
                
            # Check for ID3v1.1 track number
            if id3v1_data[125] == 0 and id3v1_data[126] != 0:
                tags['track_number'] = id3v1_data[126]
        except:
            pass
        
        return tags

def update_mp3_tags_custom(file_path, track_number, title=None, album=None):
    """Update MP3 tags using custom implementation."""
    try:
        writer = SimpleID3Writer()
        
        # Try ID3v2 first (more flexible)
        success, message = writer.write_id3v2_simple(file_path, track_number, title, album)
        if success:
            return True, "Custom ID3v2 tag updated"
        
        # Fallback to ID3v1
        success, message = writer.write_id3v1(file_path, title=title, album=album, track_number=track_number)
        if success:
            return True, "Custom ID3v1 tag updated"
        
        return False, f"Both ID3 methods failed: {message}"
    except Exception as e:
        return False, str(e)

def check_dependencies():
    """Check which MP3 tagging method is available."""
    methods = ['custom']  # Always available
    
    # Check for external tools (optional)
    try:
        import subprocess
        result = subprocess.run(['id3v2', '--version'], capture_output=True)
        if result.returncode == 0:
            methods.append('id3v2')
    except:
        pass
    
    try:
        import mutagen
        methods.append('mutagen')
    except ImportError:
        pass
    
    return methods

def update_single_file(file_path, track_number, title=None, album=None, method='auto'):
    """Update a single MP3 file's tags."""
    if not os.path.exists(file_path):
        return False, f"File not found: {file_path}"
    
    if not file_path.lower().endswith('.mp3'):
        return False, f"Not an MP3 file: {file_path}"
    
    available_methods = check_dependencies()
    
    # Choose method (prefer custom since it's always available)
    if method == 'auto':
        method = 'custom' if 'custom' in available_methods else available_methods[0]
    
    if method not in available_methods:
        return False, f"Method '{method}' not available. Available: {', '.join(available_methods)}"
    
    # Update tags
    if method == 'custom':
        return update_mp3_tags_custom(file_path, track_number, title, album)
    else:
        return False, f"Method '{method}' not supported in this version"

def update_directory(directory_path, method='auto'):
    """Update all MP3 files in a directory."""
    if not os.path.isdir(directory_path):
        return False, f"Directory not found: {directory_path}"
    
    results = []
    
    # Find MP3 files with track numbers
    for file_path in Path(directory_path).glob("*.mp3"):
        filename = file_path.stem
        
        # Try to extract track number from filename
        # Supports formats like: "001 Book Title", "001_something", "001"
        track_number = None
        title = None
        
        if filename.startswith(tuple('0123456789')):
            # Look for track number at start
            parts = filename.split(' ', 1)
            try:
                track_number = int(parts[0])
                if len(parts) > 1:
                    title = parts[1]
            except ValueError:
                # Try other patterns
                import re
                match = re.match(r'^(\d+)', filename)
                if match:
                    track_number = int(match.group(1))
        
        if track_number is not None:
            success, message = update_single_file(str(file_path), track_number, title, method)
            results.append({
                'file': file_path.name,
                'track': track_number,
                'title': title,
                'success': success,
                'message': message
            })
    
    return True, results

def main():
    parser = argparse.ArgumentParser(description='Update MP3 track number tags')
    parser.add_argument('path', nargs='?', help='MP3 file or directory path')
    parser.add_argument('--track', '-t', type=int, help='Track number (for single file)')
    parser.add_argument('--title', help='Title (for single file)')
    parser.add_argument('--album', help='Album name (for single file)')
    parser.add_argument('--method', choices=['auto', 'custom'], 
                       default='auto', help='Method to use for updating tags (custom = no dependencies)')
    parser.add_argument('--check-deps', action='store_true', 
                       help='Check available methods and exit')
    parser.add_argument('--read-tags', action='store_true',
                       help='Read and display existing tags from file')
    
    args = parser.parse_args()
    
    if args.check_deps:
        methods = check_dependencies()
        print(f"Available methods: {', '.join(methods)}")
        print("'custom' method uses built-in ID3 tag writer (no dependencies)")
        if len(methods) > 1:
            print("External tools found:", ', '.join(m for m in methods if m != 'custom'))
        sys.exit(0)
    
    if args.read_tags:
        if not args.path:
            parser.error("path is required when using --read-tags")
        
        if not os.path.isfile(args.path):
            print("Error: File not found", file=sys.stderr)
            sys.exit(1)
        
        if not args.path.lower().endswith('.mp3'):
            print("Error: Not an MP3 file", file=sys.stderr)
            sys.exit(1)
        
        # Read existing tags
        writer = SimpleID3Writer()
        tags = writer.read_existing_tags(args.path)
        
        if 'error' in tags:
            print(f"Error reading tags: {tags['error']}", file=sys.stderr)
            sys.exit(1)
        
        # Output in format Swift can parse
        if tags.get('track_number') is not None:
            print(f"Track: {tags['track_number']}")
        if tags.get('title'):
            print(f"Title: {tags['title']}")
        if tags.get('album'):
            print(f"Album: {tags['album']}")
        if tags.get('artist'):
            print(f"Artist: {tags['artist']}")
        
        sys.exit(0)
    
    if not args.path:
        parser.error("path is required unless using --check-deps or --read-tags")
    
    if os.path.isfile(args.path):
        # Single file
        if args.track is None:
            print("Error: --track required for single file", file=sys.stderr)
            sys.exit(1)
        
        success, message = update_single_file(args.path, args.track, args.title, args.album, args.method)
        if success:
            print(f"✓ Updated: {os.path.basename(args.path)} → Track #{args.track}")
        else:
            print(f"✗ Failed: {message}", file=sys.stderr)
            sys.exit(1)
    
    elif os.path.isdir(args.path):
        # Directory
        success, results = update_directory(args.path, args.method)
        if not success:
            print(f"✗ {results}", file=sys.stderr)
            sys.exit(1)
        
        success_count = 0
        for result in results:
            if result['success']:
                print(f"✓ {result['file']} → Track #{result['track']}")
                success_count += 1
            else:
                print(f"✗ {result['file']}: {result['message']}", file=sys.stderr)
        
        print(f"\nProcessed {len(results)} files, {success_count} successful")
        
        if success_count < len(results):
            sys.exit(1)
    
    else:
        print(f"Error: Path not found: {args.path}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

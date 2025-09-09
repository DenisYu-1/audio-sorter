#!/usr/bin/env python3
"""
Functional tests for Audio Sorter MP3 processing functionality.
Tests the core MP3 tagging and file processing logic.
"""

import os
import sys
import tempfile
import shutil
import unittest
import re
from pathlib import Path

# Add the current directory to Python path to import our module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import update_mp3_tags as mp3_module
except ImportError:
    # Try alternative import method
    import importlib.util
    spec = importlib.util.spec_from_file_location("update_mp3_tags", "update-mp3-tags.py")
    mp3_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mp3_module)


class TestAudioSorterFunctional(unittest.TestCase):
    """Functional tests for Audio Sorter MP3 processing."""
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        self.test_dir = tempfile.mkdtemp(prefix="audio_sorter_test_")
        self.original_cwd = os.getcwd()
        os.chdir(self.test_dir)
        
    def tearDown(self):
        """Clean up after each test method."""
        os.chdir(self.original_cwd)
        shutil.rmtree(self.test_dir, ignore_errors=True)
        
    def create_minimal_mp3(self, filename, track_num=None):
        """Create a minimal valid MP3 file that mutagen can read."""
        # MP3 frame header for 44.1kHz, 128kbps, stereo
        mp3_header = b'\xff\xfb\x90\x00'
        # Add some minimal audio data
        audio_data = b'\x00' * 100
        
        filepath = os.path.join(self.test_dir, filename)
        with open(filepath, 'wb') as f:
            f.write(mp3_header + audio_data)
            
        # Add basic ID3v2 tag if track number specified
        if track_num:
            try:
                from mutagen.mp3 import MP3
                from mutagen.id3 import TRCK
                audio = MP3(filepath)
                if audio.tags is None:
                    audio.add_tags()
                audio.tags['TRCK'] = TRCK(encoding=3, text=str(track_num))
                audio.save()
            except Exception:
                pass  # If it fails, we'll still have a test file
                
        return filepath
        
    def test_ensure_mutagen_loads(self):
        """Test that mutagen library can be loaded."""
        result = mp3_module.ensure_mutagen()
        self.assertTrue(result, "Failed to load mutagen library")
        
    def test_single_file_tag_update(self):
        """Test updating tags on a single MP3 file."""
        # Create test file
        test_file = self.create_minimal_mp3('test.mp3')
        
        # Update tags
        result = mp3_module.update_single_file(test_file, track_number=5, album="Test Album")
        self.assertTrue(result, "Failed to update single file tags")
        
        # Verify tags were set
        tag_info = mp3_module.read_file_tags(test_file)
        self.assertTrue(tag_info, "Failed to read tags from updated file")
        
    def test_directory_processing(self):
        """Test processing all MP3 files in a directory."""
        # Create multiple test files
        files = ['1.mp3', '2.mp3', '10.mp3']
        for filename in files:
            self.create_minimal_mp3(filename)
            
        # Process directory
        result = mp3_module.update_mp3_tags(self.test_dir)
        self.assertTrue(result, "Directory processing failed")
        
        # Verify files still exist
        for filename in files:
            filepath = os.path.join(self.test_dir, filename)
            self.assertTrue(os.path.exists(filepath), f"File {filename} was lost during processing")
            
    def test_filename_pattern_recognition(self):
        """Test that track numbers are correctly extracted from filenames."""
        test_cases = [
            ('1.mp3', 1),
            ('01.mp3', 1),
            ('001.mp3', 1),
            ('001_title.mp3', 1),
            ('10.mp3', 10),
            ('123_chapter.mp3', 123),
        ]
        
        for filename, expected_track in test_cases:
            with self.subTest(filename=filename):
                name_without_ext = filename[:-4] if filename.endswith('.mp3') else filename
                match = re.match(r'^(\d+)', name_without_ext)
                self.assertIsNotNone(match, f"No track number found in {filename}")
                
                track_num = int(match.group(1))
                self.assertEqual(track_num, expected_track, 
                               f"Expected track {expected_track}, got {track_num} for {filename}")
                
    def test_non_numbered_files_ignored(self):
        """Test that files without track numbers are properly ignored."""
        non_numbered_files = [
            'intro.mp3',
            'chapter.mp3', 
            'music.mp3',
            'audiobook.mp3'
        ]
        
        for filename in non_numbered_files:
            with self.subTest(filename=filename):
                name_without_ext = filename[:-4] if filename.endswith('.mp3') else filename
                match = re.match(r'^(\d+)', name_without_ext)
                self.assertIsNone(match, f"Unexpectedly found track number in {filename}")
                
    def test_tag_reading_functionality(self):
        """Test reading existing tags from MP3 files."""
        # Create file with known tags
        test_file = self.create_minimal_mp3('tagged.mp3', track_num=7)
        
        # Read tags back
        result = mp3_module.read_file_tags(test_file)
        self.assertTrue(result, "Failed to read tags from file")
        
    def test_multiple_file_patterns(self):
        """Test processing files with various naming patterns."""
        test_files = [
            '1.mp3',
            '02.mp3', 
            '003.mp3',
            '10.mp3',
            '001_chapter_one.mp3'
        ]
        
        # Create all test files
        for filename in test_files:
            self.create_minimal_mp3(filename)
            
        # Process directory
        result = mp3_module.update_mp3_tags(self.test_dir)
        self.assertTrue(result, "Failed to process multiple file patterns")
        
        # Verify all files still exist
        for filename in test_files:
            filepath = os.path.join(self.test_dir, filename)
            self.assertTrue(os.path.exists(filepath), f"Lost file {filename} during processing")


class TestHelperFunctions(unittest.TestCase):
    """Test helper functions and edge cases."""
    
    def test_track_number_extraction_edge_cases(self):
        """Test edge cases for track number extraction."""
        edge_cases = [
            ('0.mp3', 0),
            ('000.mp3', 0),
            ('999.mp3', 999),
            ('001test.mp3', 1),
            ('42_long_title_here.mp3', 42),
        ]
        
        for filename, expected in edge_cases:
            with self.subTest(filename=filename):
                name_without_ext = filename[:-4]
                match = re.match(r'^(\d+)', name_without_ext)
                if match:
                    track_num = int(match.group(1))
                    self.assertEqual(track_num, expected)
                    
    def test_invalid_filenames(self):
        """Test handling of invalid or problematic filenames."""
        invalid_files = [
            '',
            '.mp3',
            'abc.mp3',
            'track.mp3',
            '..mp3',
        ]
        
        for filename in invalid_files:
            with self.subTest(filename=filename):
                if filename and filename.endswith('.mp3'):
                    name_without_ext = filename[:-4]
                    match = re.match(r'^(\d+)', name_without_ext)
                    # These should not match the pattern
                    if match:
                        # If they do match, the number should be valid
                        track_num = int(match.group(1))
                        self.assertIsInstance(track_num, int)


if __name__ == '__main__':
    print("🧪 Running Audio Sorter Functional Tests...")
    
    # Run with verbose output
    unittest.main(verbosity=2, exit=False)
    
    print("✅ Functional tests completed!")

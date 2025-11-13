#!/usr/bin/env python3
"""
Simple test runner for Python functional tests.
Can be used independently or called from the main test runner.
"""

import sys
import os
import subprocess

def main():
    """Run Python functional tests."""
    print("🐍 Python Test Runner for Audio Sorter")
    print("=====================================")
    
    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    # Check if test file exists
    test_file = "test_functional.py"
    if not os.path.exists(test_file):
        print(f"❌ Test file not found: {test_file}")
        return 1
    
    # Try to import mutagen
    try:
        import mutagen
        print("✅ mutagen library is available")
    except ImportError:
        print("⚠️ Installing mutagen...")
        
        # Try different installation methods for compatibility
        install_commands = [
            [sys.executable, "-m", "pip", "install", "mutagen", "--break-system-packages"],
            [sys.executable, "-m", "pip", "install", "mutagen", "--user"],
            ["pip3", "install", "mutagen", "--break-system-packages"],
            ["pip3", "install", "mutagen", "--user"]
        ]
        
        installed = False
        for cmd in install_commands:
            try:
                subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"✅ mutagen installed successfully with: {' '.join(cmd[-2:])}")
                installed = True
                break
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue
        
        if not installed:
            print("❌ Failed to install mutagen with any method")
            print("Please install manually:")
            print("  pip3 install mutagen --user")
            print("  or: pip3 install mutagen --break-system-packages")
            return 1
    
    # Run the tests
    print("\n🧪 Running functional tests...")
    try:
        # Import and run the test module
        import test_functional
        
        # If we got here without import errors, the tests should work
        result = subprocess.run([sys.executable, test_file], capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print("Stderr:", result.stderr)
            
        if result.returncode == 0:
            print("✅ All Python tests passed!")
            return 0
        else:
            print("❌ Some Python tests failed")
            return result.returncode
            
    except Exception as e:
        print(f"❌ Error running tests: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

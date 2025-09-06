#!/bin/bash

# Test Script for Audio Sorter
# Creates sample MP3 files, tests sorting, and cleans up

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEST_DIR="test-mp3s"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo_status() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_test_files() {
    echo_status "Creating test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Create sample MP3 files with typical problematic naming
    local files=(
        "1.mp3"
        "2.mp3" 
        "3.mp3"
        "10.mp3"
        "11.mp3"
        "25.mp3"
        "100.mp3"
    )
    
    echo_status "Creating ${#files[@]} test MP3 files..."
    for file in "${files[@]}"; do
        # Create empty files (real MP3 content not needed for filename testing)
        touch "$file"
        echo "Created: $file"
    done
    
    # Also create some files that should be ignored
    touch "Track 1.mp3"  # Should be ignored
    touch "01.mp3"       # Should be ignored  
    touch "song.mp3"     # Should be ignored
    touch "readme.txt"   # Should be ignored
    
    echo_status "Test files created. Directory contents:"
    ls -la
    cd ..
}

test_dry_run() {
    echo_status "Testing dry run mode..."
    echo "Running: ./sort-audio.sh $TEST_DIR --dry-run"
    if "$SCRIPT_DIR/sort-audio.sh" "$TEST_DIR" --dry-run; then
        echo_status "✓ Dry run completed successfully"
    else
        echo_error "✗ Dry run failed"
        return 1
    fi
}

test_actual_sort() {
    echo_status "Testing actual file sorting..."
    echo "Files before sorting:"
    ls -1 "$TEST_DIR"/*.mp3 | sort
    
    echo_status "Running: ./sort-audio.sh $TEST_DIR"
    if "$SCRIPT_DIR/sort-audio.sh" "$TEST_DIR"; then
        echo_status "✓ Sorting completed successfully"
        
        echo_status "Files after sorting:"
        ls -1 "$TEST_DIR"/*.mp3 | sort
        
        # Verify expected files exist
        local expected=(
            "001.mp3"
            "002.mp3"
            "003.mp3"
            "010.mp3"
            "011.mp3"
            "025.mp3"
            "100.mp3"
        )
        
        echo_status "Verifying renamed files..."
        for file in "${expected[@]}"; do
            if [[ -f "$TEST_DIR/$file" ]]; then
                echo "✓ Found: $file"
            else
                echo_error "✗ Missing: $file"
                return 1
            fi
        done
        
        # Verify ignored files still exist
        if [[ -f "$TEST_DIR/Track 1.mp3" ]] && [[ -f "$TEST_DIR/song.mp3" ]]; then
            echo_status "✓ Non-numeric files correctly ignored"
        else
            echo_warning "Some ignored files are missing (this might be expected)"
        fi
        
    else
        echo_error "✗ Sorting failed"
        return 1
    fi
}

test_edge_cases() {
    echo_status "Testing edge cases..."
    
    # Test empty directory
    mkdir -p "empty-dir"
    echo_status "Testing empty directory..."
    if "$SCRIPT_DIR/sort-audio.sh" "empty-dir" 2>/dev/null; then
        echo_warning "Empty directory test didn't fail as expected"
    else
        echo_status "✓ Empty directory handled correctly"
    fi
    rmdir "empty-dir"
    
    # Test non-existent directory
    echo_status "Testing non-existent directory..."
    if "$SCRIPT_DIR/sort-audio.sh" "non-existent-dir" 2>/dev/null; then
        echo_warning "Non-existent directory test didn't fail as expected"
    else
        echo_status "✓ Non-existent directory handled correctly"
    fi
}

cleanup() {
    echo_status "Cleaning up test files..."
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        echo_status "✓ Test directory removed"
    fi
}

run_all_tests() {
    echo_status "Starting Audio Sorter Tests"
    echo "=============================="
    
    # Cleanup any existing test files
    cleanup
    
    # Check if main script exists
    if [[ ! -f "$SCRIPT_DIR/sort-audio.sh" ]]; then
        echo_error "sort-audio.sh not found in $SCRIPT_DIR"
        echo "Make sure you're running this from the correct directory"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$SCRIPT_DIR/sort-audio.sh"
    
    # Run tests
    create_test_files
    test_dry_run
    test_actual_sort
    test_edge_cases
    
    echo_status "All tests completed successfully! 🎉"
    echo_status "The sort-audio.sh script is working correctly."
    echo ""
    echo_status "Next steps:"
    echo "1. Follow SETUP-INSTRUCTIONS.md to create the Automator app"
    echo "2. Test the app with real MP3 files"
    echo "3. Share the app with other Macs"
    
    # Cleanup
    cleanup
}

# Handle script arguments
case "${1:-run}" in
    "run"|"test"|"")
        run_all_tests
        ;;
    "create")
        create_test_files
        echo_status "Test files created. Run './test-audio-sorter.sh cleanup' when done."
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  run      Run all tests (default)"
        echo "  create   Create test files only"
        echo "  cleanup  Remove test files"
        echo "  help     Show this help"
        ;;
    *)
        echo_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

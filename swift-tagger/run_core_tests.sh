#!/bin/bash

# Audio Sorter Core Functionality Test Runner
# Tests specific modules: rename, tags, preserve

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Help function
show_help() {
    echo "Audio Sorter Core Tests"
    echo "Usage: $0 [MODULE]"
    echo ""
    echo "Modules:"
    echo "  rename     Test file renaming (1.mp3 -> 001.mp3)"
    echo "  tags       Test meta tag updates"
    echo "  preserve   Test existing tag preservation"
    echo "  all        Run all core tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0           # Run all tests"
    echo "  $0 rename    # Test only file renaming"
    echo "  $0 tags      # Test only tag updates"
}

# Parse arguments
MODULE="all"
if [ $# -gt 0 ]; then
    case $1 in
        rename|tags|preserve|all)
            MODULE=$1
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown module: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo "🎵 Audio Sorter Core Functionality Tests"
echo "========================================"
echo "Testing module: $MODULE"
echo ""

# Check Python availability
if ! command -v python3 &> /dev/null; then
    print_error "python3 not found"
    exit 1
fi

# Check if test file exists
if [ ! -f "test_core_functionality.py" ]; then
    print_error "Test file not found: test_core_functionality.py"
    exit 1
fi

# Try to install mutagen if needed
if ! python3 -c "import mutagen" 2>/dev/null; then
    print_warning "mutagen not available, attempting to install..."
    
    # Try different installation methods
    if pip3 install mutagen --break-system-packages 2>/dev/null; then
        print_status "Installed mutagen with --break-system-packages"
    elif pip3 install mutagen --user 2>/dev/null; then
        print_status "Installed mutagen with --user"
    elif python3 -m pip install mutagen --break-system-packages 2>/dev/null; then
        print_status "Installed mutagen via python -m pip"
    else
        print_warning "Could not install mutagen - tests may have limited functionality"
    fi
fi

# Run the specific test module
print_info "Running core functionality tests..."
if python3 test_core_functionality.py --module "$MODULE"; then
    print_status "Core tests completed successfully!"
    exit 0
else
    print_error "Core tests failed!"
    exit 1
fi

#!/bin/bash

# Audio Sorter - Fix numeric MP3 file naming for proper sorting
# Handles files like: 1.mp3, 2.mp3, 10.mp3 -> 01.mp3, 02.mp3, 10.mp3

set -e

sort_audio_files() {
    local target_dir="$1"
    local dry_run="${2:-false}"
    local update_tags="${3:-true}"
    
    # Validate directory
    if [[ ! -d "$target_dir" ]]; then
        echo "Error: Directory '$target_dir' does not exist"
        return 1
    fi
    
    # Find all numeric MP3 files and get the maximum number
    local max_num=0
    local files_found=()
    
    while IFS= read -r -d '' file; do
        local filename=$(basename "$file")
        # Extract number from filename (e.g., "1.mp3" -> "1")
        if [[ $filename =~ ^([0-9]+)\.mp3$ ]]; then
            local num=${BASH_REMATCH[1]}
            # Remove leading zeros for comparison
            num=$((10#$num))
            if (( num > max_num )); then
                max_num=$num
            fi
            files_found+=("$file")
        fi
    done < <(find "$target_dir" -maxdepth 1 -name "*.mp3" -print0)
    
    if [[ ${#files_found[@]} -eq 0 ]]; then
        echo "No numeric MP3 files found in '$target_dir'"
        return 1
    fi
    
    # Determine padding length based on maximum number
    local padding_length=${#max_num}
    
    echo "Found ${#files_found[@]} files, max number: $max_num"
    echo "Using $padding_length-digit padding"
    
    if [[ "$dry_run" == "true" ]]; then
        echo "DRY RUN - No files will be renamed"
    fi
    
    # Process each file
    local renamed_count=0
    for file in "${files_found[@]}"; do
        local filename=$(basename "$file")
        local dirname=$(dirname "$file")
        
        if [[ $filename =~ ^([0-9]+)\.mp3$ ]]; then
            local original_num=${BASH_REMATCH[1]}
            # Remove leading zeros for processing
            local num=$((10#$original_num))
            
            # Create zero-padded filename
            local padded_num=$(printf "%0${padding_length}d" $num)
            local new_filename="${padded_num}.mp3"
            local new_path="$dirname/$new_filename"
            
            # Skip if already properly named
            if [[ "$filename" == "$new_filename" ]]; then
                continue
            fi
            
            # Check if target file already exists
            if [[ -e "$new_path" ]]; then
                echo "Warning: '$new_filename' already exists, skipping '$filename'"
                continue
            fi
            
            if [[ "$dry_run" == "true" ]]; then
                echo "Would rename: $filename -> $new_filename"
            else
                mv "$file" "$new_path"
                echo "Renamed: $filename -> $new_filename"
            fi
            
            ((renamed_count++))
        fi
    done
    
    if [[ "$dry_run" == "true" ]]; then
        echo "Dry run complete. $renamed_count files would be renamed."
        if [[ "$update_tags" == "true" ]]; then
            echo "Tag updates would also be performed."
        fi
    else
        echo "Complete! $renamed_count files renamed."
        
        # Update MP3 tags if requested and files were renamed
        if [[ "$update_tags" == "true" && $renamed_count -gt 0 ]]; then
            echo "Updating MP3 track numbers..."
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            
            if [[ -f "$script_dir/update-mp3-tags.py" ]]; then
                if python3 "$script_dir/update-mp3-tags.py" "$target_dir"; then
                    echo "✓ MP3 tags updated successfully"
                else
                    echo "⚠ Warning: Failed to update MP3 tags (files renamed successfully)"
                fi
            else
                echo "⚠ Warning: update-mp3-tags.py not found, skipping tag updates"
            fi
        fi
    fi
    
    return 0
}

# Main execution when called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET_DIR="${1:-.}"
    DRY_RUN=false
    UPDATE_TAGS=true
    
    # Parse command line arguments
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                ;;
            --no-tags)
                UPDATE_TAGS=false
                ;;
            --help|-h)
                echo "Usage: $0 [directory] [options]"
                echo ""
                echo "Options:"
                echo "  --dry-run    Preview changes without making them"
                echo "  --no-tags    Skip updating MP3 track number tags"
                echo "  --help, -h   Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                           # Sort current directory"
                echo "  $0 /path/to/music           # Sort specific directory"
                echo "  $0 /path/to/music --dry-run # Preview changes only"
                echo "  $0 /path/to/music --no-tags # Rename files but don't update tags"
                exit 0
                ;;
            -*)
                echo "Unknown option: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                # Assume it's a directory path
                if [[ "$arg" != "$1" ]]; then
                    echo "Error: Multiple directories specified"
                    exit 1
                fi
                ;;
        esac
    done
    
    # If first argument is a flag, use current directory
    if [[ "$1" == --* ]]; then
        TARGET_DIR="."
    fi
    
    sort_audio_files "$TARGET_DIR" "$DRY_RUN" "$UPDATE_TAGS"
fi

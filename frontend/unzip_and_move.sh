#!/bin/bash

# Script to unzip files and move contents to buildbeacon directory
# Usage: ./unzip_and_move.sh [zip_file_path]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [zip_file_path]"
    echo ""
    echo "Options:"
    echo "  zip_file_path    Path to the zip file to extract (optional)"
    echo "                   If not provided, will look for zip files in current directory"
    echo ""
    echo "Examples:"
    echo "  $0                           # Extract all zip files in current directory"
    echo "  $0 buildbeacon.zip          # Extract specific zip file"
    echo "  $0 /path/to/file.zip        # Extract zip file from specific path"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to extract zip file
extract_zip() {
    local zip_file="$1"
    local temp_dir="$2"
    
    print_info "Extracting $zip_file..."
    
    if command_exists unzip; then
        unzip -q "$zip_file" -d "$temp_dir"
    elif command_exists 7z; then
        7z x "$zip_file" -o"$temp_dir" -y
    else
        print_error "Neither 'unzip' nor '7z' command found. Please install one of them."
        return 1
    fi
    
    print_success "Successfully extracted $zip_file"
}

# Function to move files from extracted directory to buildbeacon
move_files() {
    local source_dir="$1"
    local target_dir="$2"
    
    print_info "Moving files from $source_dir to $target_dir..."
    
    # Find the main extracted directory (usually the first directory in temp)
    local extracted_dir=$(find "$source_dir" -maxdepth 1 -type d ! -path "$source_dir" | head -1)
    
    if [ -z "$extracted_dir" ]; then
        print_warning "No directory found in extracted files, moving files directly"
        extracted_dir="$source_dir"
    fi
    
    print_info "Source directory: $extracted_dir"
    print_info "Target directory: $target_dir"
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Move all contents from extracted directory to target
    if [ -d "$extracted_dir" ]; then
        # Move all files and directories
        find "$extracted_dir" -mindepth 1 -maxdepth 1 -exec mv {} "$target_dir/" \;
        print_success "Files moved successfully"
    else
        print_error "Extracted directory not found: $extracted_dir"
        return 1
    fi
}

# Function to clean up temporary directory
cleanup() {
    local temp_dir="$1"
    if [ -d "$temp_dir" ]; then
        print_info "Cleaning up temporary directory: $temp_dir"
        rm -rf "$temp_dir"
    fi
}

# Main function
main() {
    local zip_file="$1"
    local buildbeacon_dir="./buildbeacon"
    local temp_dir="./temp_extract_$$"
    
    print_info "Starting unzip and move operation..."
    
    # Check if buildbeacon directory exists
    if [ ! -d "$buildbeacon_dir" ]; then
        print_warning "buildbeacon directory not found, creating it..."
        mkdir -p "$buildbeacon_dir"
    fi
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Set up cleanup trap
    trap "cleanup '$temp_dir'" EXIT
    
    if [ -n "$zip_file" ]; then
        # Extract specific zip file
        if [ ! -f "$zip_file" ]; then
            print_error "Zip file not found: $zip_file"
            exit 1
        fi
        
        extract_zip "$zip_file" "$temp_dir"
        move_files "$temp_dir" "$buildbeacon_dir"
        
    else
        # Find and extract all zip files in current directory
        local zip_files=($(find . -maxdepth 1 -name "*.zip" -type f))
        
        if [ ${#zip_files[@]} -eq 0 ]; then
            print_warning "No zip files found in current directory"
            show_usage
            exit 1
        fi
        
        print_info "Found ${#zip_files[@]} zip file(s):"
        for file in "${zip_files[@]}"; do
            echo "  - $file"
        done
        
        for zip_file in "${zip_files[@]}"; do
            print_info "Processing: $zip_file"
            
            # Create a unique temp directory for each zip file
            local current_temp_dir="$temp_dir/$(basename "$zip_file" .zip)"
            mkdir -p "$current_temp_dir"
            
            extract_zip "$zip_file" "$current_temp_dir"
            move_files "$current_temp_dir" "$buildbeacon_dir"
        done
    fi
    
    print_success "Operation completed successfully!"
    print_info "Files have been moved to: $buildbeacon_dir"
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"

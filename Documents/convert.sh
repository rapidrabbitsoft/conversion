#!/bin/bash

# Color codes for pretty output
RED='\033[1;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
LIGHT_YELLOW='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
input_ext="md"
output_ext="docx"
auto_remove=false
max_parallel_jobs=4

# Log function
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Color codes for log levels
    local color
    case "$level" in
        ERROR)
            color="$RED"
            ;;
        WARNING)
            color="$YELLOW"
            ;;
        SUCCESS)
            color="$GREEN"
            ;;
        INFO)
            color="$CYAN"
            ;;
        *)
            color="$NC"
            ;;
    esac
    
    # Print colored output to terminal
    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Error handling
set -e
trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    log "Error occurred in script at line $line_number with exit code $exit_code" "ERROR"
    exit $exit_code
}

# Help function to display usage
usage() {
    echo -e "${CYAN}Usage:${NC} $0 [-i input_ext] [-o output_ext] [-r auto_remove] [-j jobs]"
    echo -e "${LIGHT_YELLOW}Options:${NC}"
    echo -e "  -i  input_ext    : Specify the input file extension (default: md)"
    echo -e "  -o  output_ext   : Specify the output file extension (default: docx)"
    echo -e "  -r  auto_remove  : Auto Remove file on successful conversion (default: false)"
    echo -e "  -j  jobs         : Number of parallel conversion jobs (default: 4)"
    echo -e "  -h  or --help    : Display this help message"
    exit 0
}

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            input_ext="$2"
            shift 2
            ;;
        -o|--output)
            output_ext="$2"
            shift 2
            ;;
        -r|--remove)
            auto_remove="$2"
            shift 2
            ;;
        -j|--jobs)
            max_parallel_jobs="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option: $1"
            usage
            ;;
    esac
done

# Validate input
if ! command -v pandoc &> /dev/null; then
    log "pandoc is not installed. Please install it first." "ERROR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "Output"

# Find files with the specified input extension
IFS=$'\n' files=($(find "Input/" -type f -name "*.${input_ext}"))
if [[ ${#files[@]} -eq 0 ]]; then
    log "No ${input_ext} files found in the Input directory." "WARNING"
    exit 0
fi

# Function to convert a single file
convert_file() {
    local file="$1"
    local file_name=$(basename "$file" ".${input_ext}")
    local output_file="Output/${file_name}.${output_ext}"
    
    log "Converting: $file" "INFO"
    if pandoc "$file" -o "$output_file"; then
        log "Successfully converted: $file → $output_file" "SUCCESS"
        if [[ $auto_remove == "true" ]]; then
            rm "$file"
            log "Removed source file: $file" "INFO"
        fi
    else
        log "Conversion failed: $file" "ERROR"
        return 1
    fi
}

# Process files in parallel
log "Starting conversion of ${#files[@]} files with $max_parallel_jobs parallel jobs" "INFO"
for file in "${files[@]}"; do
    # Wait if we've reached the maximum number of parallel jobs
    while [[ $(jobs -r | wc -l) -ge $max_parallel_jobs ]]; do
        sleep 1
    done
    
    # Start conversion in background
    convert_file "$file" &
done

# Wait for all background jobs to complete
wait

log "All conversions complete." "SUCCESS"

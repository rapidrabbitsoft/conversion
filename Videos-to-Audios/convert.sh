#!/bin/bash

# Color codes for prettifying output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_YELLOW='\033[0;33m'
CYAN='\033[1;36m'
NC='\033[0m'  # No color

# Default values
VIDEO_EXT="mp4"
AUDIO_EXT="mp3"
AUDIO_CODEC="libmp3lame"  # Default to MP3 codec (lossless)
BITRATE="192k"  # Default to 192k bitrate
MAX_PARALLEL_JOBS=2
auto_remove=false

# Validate video and audio container types
VALID_VIDEO_EXTS=("mp4" "mkv" "avi" "mov" "flv" "webm")
VALID_AUDIO_FORMATS=("mp3" "aac" "wav" "flac" "ogg")

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

# Help message
usage() {
    echo -e "${CYAN}Usage${NC}:   $0 [options]"
    echo -e "\n${LIGHT_YELLOW}Options${NC}:"
    echo -e "  -i  input_ext     : Input video extension (default: mp4)"
    echo -e "  -o  output_ext    : Output audio extension (default: mp3)"
    echo -e "  -c  audio_codec   : Audio codec to use (default: libmp3lame)"
    echo -e "  -b  bitrate       : Audio bitrate (default: 192k)"
    echo -e "  -j  jobs          : Number of parallel jobs (default: 2)"
    echo -e "  -r  auto_remove   : Remove source files after conversion (default: false)"
    echo -e "  -h  or --help     : Show this help message"
    echo -e "\n${LIGHT_YELLOW}Supported Video Formats${NC}: ${VALID_VIDEO_EXTS[*]}"
    echo -e "${LIGHT_YELLOW}Supported Audio Formats${NC}: ${VALID_AUDIO_FORMATS[*]}"
    echo -e "\n${LIGHT_YELLOW}Examples${NC}:"
    echo -e "  $0 -i mp4 -o mp3"
    echo -e "  $0 -i mp4 -o mp3 -b 320k"
    echo -e "  $0 -i mp4 -o mp3 -c libmp3lame -j 4"
    exit 1
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input)
            VIDEO_EXT="$2"
            shift 2
            ;;
        -o|--output)
            AUDIO_EXT="$2"
            shift 2
            ;;
        -c|--codec)
            AUDIO_CODEC="$2"
            shift 2
            ;;
        -b|--bitrate)
            BITRATE="$2"
            shift 2
            ;;
        -j|--jobs)
            MAX_PARALLEL_JOBS="$2"
            shift 2
            ;;
        -r|--remove)
            auto_remove="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log "Unknown option: $1" "ERROR"
            usage
            ;;
    esac
done

# Validate FFmpeg installation
if ! command -v ffmpeg &> /dev/null; then
    log "FFmpeg is not installed. Please install it first." "ERROR"
    exit 1
fi

# Validate video format
if [[ ! " ${VALID_VIDEO_EXTS[@]} " =~ " ${VIDEO_EXT} " ]]; then
    log "Invalid video format. Supported formats: ${VALID_VIDEO_EXTS[*]}" "ERROR"
    exit 1
fi

# Validate audio format
if [[ ! " ${VALID_AUDIO_FORMATS[@]} " =~ " ${AUDIO_EXT} " ]]; then
    log "Invalid audio format. Supported formats: ${VALID_AUDIO_FORMATS[*]}" "ERROR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "Output"

# Function to convert a single file
convert_file() {
    local input_file="$1"
    local output_file="Output/$(basename -- "${input_file%.*}").${AUDIO_EXT}"
    
    log "Converting: $input_file → $output_file" "INFO"
    
    if ffmpeg -hide_banner -y -i "$input_file" -vn -acodec "$AUDIO_CODEC" -ab "$BITRATE" "$output_file"; then
        log "Successfully converted: $input_file → $output_file" "SUCCESS"
        if [[ "$auto_remove" == "true" ]]; then
            rm "$input_file"
            log "Removed source file: $input_file" "INFO"
        fi
    else
        log "Conversion failed: $input_file" "ERROR"
        return 1
    fi
}

# Process files
log "Starting audio extraction with $MAX_PARALLEL_JOBS parallel jobs" "INFO"

# Find all valid video files
shopt -s nullglob
files=()
for ext in "${VALID_VIDEO_EXTS[@]}"; do
    files+=("Input"/*."$ext")
done

# Process files in parallel
for file in "${files[@]}"; do
    # Skip if not a file
    [[ -f "$file" ]] || continue
    
    # Wait if we've reached the maximum number of parallel jobs
    while [[ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]]; do
        sleep 1
    done
    
    # Start conversion in background
    convert_file "$file" &
done

# Wait for all background jobs to complete
wait

log "All conversions complete" "SUCCESS"

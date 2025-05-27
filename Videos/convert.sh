#!/bin/bash

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
LIGHT_YELLOW='\033[0;33m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Default values
AUDIO_RANGE=""
VIDEO_RANGE=""
SUBTITLE_RANGE=""
OUTPUT_EXT="mp4"  # Default to mp4
SHOW_PROGRESS_ONLY=false
MAX_PARALLEL_JOBS=2
auto_remove=false

# Supported formats
VALID_EXTENSIONS=("mp4" "m4v" "f4v" "mov" "avi" "ogv" "mkv" "wmv" "ts" "vob" "m2ts" "flv" "webm" "mpeg" "mpg" "3gp" "wmv")

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

usage() {
    echo -e "${CYAN}Usage:${NC} $0 [options]"
    echo -e "${LIGHT_YELLOW}Options:${NC}"
    echo -e "  -a, --audio TRACKS    Select audio tracks (e.g. 0 or 0-1), (default: all tracks)"
    echo -e "  -v, --video TRACKS    Select video tracks (e.g. 0 or 0-1), (default: all tracks)"
    echo -e "  -s, --subtitles TRACKS Select subtitle tracks (e.g. 0 or 0-1), (default: all tracks)"
    echo -e "  -e, --ext EXTENSION   Set the output file extension (default: mp4)"
    echo -e "  -p, --progress        Show only progress (percentage) and suppress FFmpeg output"
    echo -e "  -j, --jobs JOBS       Number of parallel conversion jobs (default: 2)"
    echo -e "  -r, --remove          Remove source video after conversion (default: false)"
    echo -e "  -h, --help            Show this help message"
    echo -e "\n${LIGHT_YELLOW}Supported Formats:${NC} ${VALID_EXTENSIONS[*]}"
    echo -e "\n${LIGHT_YELLOW}Examples:${NC}"
    echo -e "  $0"
    echo -e "  $0 -a 0-1 -v 0-0"
    echo -e "  $0 -a 0-1 -v 0-0 -e mp4 -j 4"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -a|--audio)
            AUDIO_RANGE="$2"
            shift 2
            ;;
        -v|--video)
            VIDEO_RANGE="$2"
            shift 2
            ;;
        -s|--subtitles)
            SUBTITLE_RANGE="$2"
            shift 2
            ;;
        -e|--ext)
            OUTPUT_EXT="$2"
            shift 2
            ;;
        -p|--progress)
            SHOW_PROGRESS_ONLY=true
            shift
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
            exit 0
            ;;
        *)
            log "Unknown option: $1" "ERROR"
            usage
            exit 1
            ;;
    esac
done

# Validate FFmpeg installation
if ! command -v ffmpeg &> /dev/null; then
    log "FFmpeg is not installed. Please install it first." "ERROR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "Output"

# Convert range like 0-2 to -map 0:a:0 -map 0:a:1 ...
parse_range() {
    local type="$1"
    local range="$2"
    local map_args=()

    if [[ "$range" =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r START END <<< "$range"
        for (( i=START; i<=END; i++ )); do
            map_args+=("-map" "0:${type}:${i}")
        done
    elif [[ "$range" =~ ^[0-9]+$ ]]; then
        map_args+=("-map" "0:${type}:${range}")
    else
        map_args+=("-map" "0:${type}")
    fi

    echo "${map_args[@]}"
}

# Function to calculate and display progress
show_progress() {
    local duration="$1"
    local current_time="$2"

    IFS=':' read -r hh mm ss <<< "$current_time"
    ss_frac=$(echo "$ss" | awk '{printf "%.2f", $1}')
    current_sec=$(echo "$hh * 3600 + $mm * 60 + $ss_frac" | bc)

    percent=$(echo "$current_sec / $duration * 100" | bc -l)
    printf "\r${YELLOW}Progress${NC}: %5.1f%%" "$percent"
}

# Get duration in seconds using ffprobe
get_duration() {
    local input_file="$1"
    ffprobe -v error -select_streams v:0 -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$input_file"
}

# Function to convert a single file
convert_file() {
    local input_file="$1"
    local output_file="Output/$(basename -- "${input_file%.*}").${OUTPUT_EXT}"
    local ext_lc=$(echo "${input_file##*.}" | tr '[:upper:]' '[:lower:]')

    log "Processing: $input_file → $output_file" "INFO"

    # Get duration of the input video file
    local duration=$(get_duration "$input_file")

    # Special handling for wma files
    if [[ "$ext_lc" == "wma" ]]; then
        log "Transcoding WMV to MP4..." "INFO"
        if ffmpeg -hide_banner -y -i "$input_file" -c:v libx264 -crf 23 -c:a aac -b:a 192k "$output_file" -nostdin; then
            log "Conversion complete: $output_file" "SUCCESS"
            if [[ "$auto_remove" == "true" ]]; then
                rm "$input_file"
                log "Removed source file: $input_file" "INFO"
            fi
        else
            log "Conversion failed: $input_file" "ERROR"
            return 1
        fi
    else
        # For other files, mux without re-encoding
        local audio_args=()
        local video_args=()
        local subtitle_args=()

        if [[ -n "$AUDIO_RANGE" ]]; then
            audio_args=($(parse_range "a" "$AUDIO_RANGE"))
        else
            audio_args+=("-map" "0:a?")
        fi

        if [[ -n "$VIDEO_RANGE" ]]; then
            video_args=($(parse_range "v" "$VIDEO_RANGE"))
        else
            video_args+=("-map" "0:v?")
        fi

        if [[ -n "$SUBTITLE_RANGE" ]]; then
            subtitle_args=($(parse_range "s" "$SUBTITLE_RANGE"))
        else
            subtitle_args+=("-map" "0:s?")
        fi

        if [[ "$SHOW_PROGRESS_ONLY" == true ]]; then
            if ffmpeg -hide_banner -y -i "$input_file" \
                "${video_args[@]}" "${audio_args[@]}" "${subtitle_args[@]}" \
                -c copy -strict -2 "$output_file" 2>&1 | \
                while IFS= read -r line; do
                    if [[ $line =~ time=([0-9:.]+) ]]; then
                        show_progress "$duration" "${BASH_REMATCH[1]}"
                    fi
                done; then
                echo
                log "Conversion complete: $output_file" "SUCCESS"
                if [[ "$auto_remove" == "true" ]]; then
                    rm "$input_file"
                    log "Removed source file: $input_file" "INFO"
                fi
            else
                log "Conversion failed: $input_file" "ERROR"
                return 1
            fi
        else
            if ffmpeg -hide_banner -y -i "$input_file" \
                "${video_args[@]}" "${audio_args[@]}" "${subtitle_args[@]}" \
                -c copy -strict -2 "$output_file"; then
                log "Conversion complete: $output_file" "SUCCESS"
                if [[ "$auto_remove" == "true" ]]; then
                    rm "$input_file"
                    log "Removed source file: $input_file" "INFO"
                fi
            else
                log "Conversion failed: $input_file" "ERROR"
                return 1
            fi
        fi
    fi
}

# Process files
log "Starting video conversion with $MAX_PARALLEL_JOBS parallel jobs" "INFO"

# Find all valid video files
shopt -s nullglob
files=()
for ext in "${VALID_EXTENSIONS[@]}"; do
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

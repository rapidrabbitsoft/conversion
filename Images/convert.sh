#!/bin/bash

# Color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
LIGHT_YELLOW='\033[0;33m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
INPUT_EXT=""
OUTPUT_EXT="jpeg"  # Default output format
QUALITY=100
OPTIMIZE=false
FILTER=""
MAX_PARALLEL_JOBS=4

# Valid formats
VALID_FORMATS=("jpg" "jpeg" "png" "gif" "bmp" "heic" "webp" "pdf" "tiff" "tif" "raw" "cr2" "nef" "arw")

# Valid filters
VALID_FILTERS=(
    "grayscale" "sepia" "invert" "blur" "sharpen" "contrast" "vignette"
    "charcoal" "sketch" "spread" "swirl" "polaroid" "oil-paint"
    "normalize" "equalize" "denoise"
)
auto_remove=true

# Initialize an array to store base filenames
declare -a processed_files=()

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
    echo -e "${CYAN}Usage${NC}:   $0 [-i input_ext[,input_ext...]] -o output_ext [-r auto_remove] [-q quality] [-f filter] [-opt] [-j jobs]"
    echo -e "\n${LIGHT_YELLOW}Options${NC}:"
    echo -e "  -i  input_ext    : Input file extension(s) (comma-separated)"
    echo -e "  -o  output_ext   : Output file extension (required)"
    echo -e "  -q  quality      : Output quality (1-100, default: 100)"
    echo -e "  -f  filter       : Apply image filter(s) (comma-separated)"
    echo -e "  -r  auto_remove  : Auto remove source images (default: true)"
    echo -e "  -j  jobs         : Number of parallel jobs (default: 4)"
    echo -e "  -opt            : Enable optimization"
    echo -e "  -h  or --help    : Display this help message"
    echo -e "\n${LIGHT_YELLOW}Supported Formats${NC}: ${VALID_FORMATS[*]}"
    echo -e "${LIGHT_YELLOW}Supported Filters${NC}: ${VALID_FILTERS[*]}"
    exit 1
}

# Function to convert a string to lowercase (portable)
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Validate extension
is_valid_output_extension() {
    local ext
    ext=$(to_lowercase "$1")
    for valid_ext in "${VALID_FORMATS[@]}"; do
        if [[ "$ext" == "$valid_ext" ]]; then
            return 0
        fi
    done
    return 1
}

is_valid_input_extension() {
    local lowercase_exts
    lowercase_exts=$(to_lowercase "$1" | tr -s '[:space:]' ',')
    IFS=',' read -ra ext_array <<< "$lowercase_exts"

    for ext in "${ext_array[@]}"; do
        local found=false
        for valid_ext in "${VALID_FORMATS[@]}"; do
            if [[ "$ext" == "$valid_ext" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            log "Invalid extension '$ext'. Supported: ${VALID_FORMATS[*]}" "ERROR"
            exit 1
        fi
    done
}

is_valid_filter() {
    local lowercase_filters
    lowercase_filters=$(to_lowercase "$1" | tr -s '[:space:]' ',')
    IFS=',' read -ra filters <<< "$lowercase_filters"

    for filter in "${filters[@]}"; do
        local found=false
        for valid in "${VALID_FILTERS[@]}"; do
            if [[ "$filter" == "$valid" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            log "Invalid filter '$filter'. Supported: ${VALID_FILTERS[*]}" "ERROR"
            exit 1
        fi
    done
}

apply_filters() {
    local filter_cmds=""
    local filters
    filters=$(to_lowercase "$1")
    IFS=',' read -ra filters <<< "$filters"
    for filter in "${filters[@]}"; do
        case "$filter" in
            grayscale)
                filter_cmds+=" -colorspace Gray"
                ;;
            sepia)
                filter_cmds+=" -sepia-tone 80%"
                ;;
            invert)
                filter_cmds+=" -negate"
                ;;
            blur)
                filter_cmds+=" -blur 0x4"
                ;;
            sharpen)
                filter_cmds+=" -sharpen 0x2"
                ;;
            vignette)
                filter_cmds+=" -vignette 0x20"
                ;;
            charcoal)
                filter_cmds+=" -charcoal 2"
                ;;
            polaroid)
                filter_cmds+=" -bordercolor white -border 25 -background white"
                ;;
            sketch)
                filter_cmds+=" -sketch 10"
                ;;
            spread)
                filter_cmds+=" -spread 10"
                ;;
            swirl)
                filter_cmds+=" -swirl 180"
                ;;
            oil-paint)
                filter_cmds+=" -paint 10"
                ;;
            normalize)
                filter_cmds+=" -normalize"
                ;;
            equalize)
                filter_cmds+=" -equalize"
                ;;
            denoise)
                filter_cmds+=" -despeckle"
                ;;
            *)
                log "Unsupported filter '$filter'" "ERROR"
                exit 1
                ;;
        esac
    done
    echo "$filter_cmds"
}

# Optimize image (JPEG, PNG, GIF)
apply_optimizations() {
    local file="$1"

    if [ -f "$file" ]; then
        case "$file" in
            *.jpg|*.jpeg)
                if command -v jpegoptim &> /dev/null; then
                    jpegoptim --strip-all --strip-iptc --strip-exif --max=85 "$file"
                else
                    log "jpegoptim not installed. Skipping JPEG optimization." "WARNING"
                fi
                ;;
            *.png)
                if command -v optipng &> /dev/null && command -v pngcrush &> /dev/null; then
                    optipng -o7 -strip all "$file"
                    pngcrush -brute -strip "$file" "$file"
                else
                    log "optipng or pngcrush not installed. Skipping PNG optimization." "WARNING"
                fi
                ;;
            *.gif)
                if command -v gifsicle &> /dev/null; then
                    gifsicle -O3 --colors 256 --no-comments --minify "$file" -o "$file"
                else
                    log "gifsicle not installed. Skipping GIF optimization." "WARNING"
                fi
                ;;
            *)
                log "No optimization support for this format" "WARNING"
                ;;
        esac
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) INPUT_EXT="$2"; shift 2 ;;
        -o) OUTPUT_EXT="$2"; shift 2 ;;
        -q) QUALITY="$2"; shift 2 ;;
        -f) FILTER="$2"; shift 2 ;;
        -r|--remove)
            auto_remove="$2"
            shift 2
            ;;
        -j|--jobs)
            MAX_PARALLEL_JOBS="$2"
            shift 2
            ;;
        -opt) OPTIMIZE=true; shift 1 ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

# Validate output extension
if [[ -z "$OUTPUT_EXT" ]]; then
    log "Output extension is required" "ERROR"
    usage
fi

OUTPUT_EXT=$(to_lowercase "$OUTPUT_EXT")

if ! is_valid_output_extension "$OUTPUT_EXT"; then
    log "Invalid output extension '$OUTPUT_EXT'. Supported: ${VALID_FORMATS[*]}" "ERROR"
    exit 1
fi

# Validate filter
if [[ -n "$FILTER" ]]; then
    if ! is_valid_filter "$FILTER"; then
        log "Invalid filter '$FILTER'. Supported filters: ${VALID_FILTERS[*]}" "ERROR"
        exit 1
    fi
fi

# Change to script directory
cd "$(dirname "$0")"

# Check for required tools
if ! command -v magick &> /dev/null; then
    log "ImageMagick 'magick' is not installed" "ERROR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "Output"

# Function to convert a single file
convert_file() {
    local input_file="$1"
    local output_file="Output/$(basename "$input_file" | sed "s/\.[^.]*$/.$OUTPUT_EXT/")"
    local filter_cmds=""
    
    if [[ -n "$FILTER" ]]; then
        filter_cmds=$(apply_filters "$FILTER")
    fi
    
    log "Converting: $input_file" "INFO"
    
    if magick "$input_file" -quality "$QUALITY" $filter_cmds "$output_file"; then
        log "Successfully converted: $input_file → $output_file" "SUCCESS"
        
        if [[ "$OPTIMIZE" == true ]]; then
            apply_optimizations "$output_file"
        fi
        
        if [[ "$auto_remove" == "true" ]]; then
            rm "$input_file"
            log "Removed source file: $input_file" "INFO"
        fi
    else
        log "Conversion failed: $input_file" "ERROR"
        return 1
    fi
}

# Find files to convert
EXT_ARRAY=()
if [[ -z "$INPUT_EXT" ]]; then
    for ext in "${VALID_FORMATS[@]}"; do
        shopt -s nullglob nocaseglob
        files=( Input/*."$ext" )
        if [[ ${#files[@]} -gt 0 ]]; then
            EXT_ARRAY+=("$ext")
        fi
    done
    if [[ ${#EXT_ARRAY[@]} -eq 0 ]]; then
        log "No image files found in Input directory" "WARNING"
        exit 0
    fi
else
    IFS=' ,;' read -ra EXT_ARRAY <<< "$(to_lowercase "$INPUT_EXT")"
    for ext in "${EXT_ARRAY[@]}"; do
        if ! is_valid_input_extension "$ext"; then
            log "Invalid input extension '$ext'. Supported: ${VALID_FORMATS[*]}" "ERROR"
            exit 1
        fi
    done
fi

# Process files in parallel
log "Starting conversion with $MAX_PARALLEL_JOBS parallel jobs" "INFO"
for ext in "${EXT_ARRAY[@]}"; do
    shopt -s nullglob nocaseglob
    files=( Input/*."$ext" )
    
    for file in "${files[@]}"; do
        # Wait if we've reached the maximum number of parallel jobs
        while [[ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]]; do
            sleep 1
        done
        
        # Start conversion in background
        convert_file "$file" &
    done
done

# Wait for all background jobs to complete
wait

log "All conversions complete" "SUCCESS"

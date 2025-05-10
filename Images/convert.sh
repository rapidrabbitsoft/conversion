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

# Help message
usage() {
    echo -e "${CYAN}Usage${NC}:   $0 [-i input_ext[,input_ext...]] -o output_ext [-r auto_remove] [-q quality] [-f filter] [-opt]"
    echo -e "\n${LIGHT_YELLOW}Remove${NC}:   Auto remove source images after conversion (default: false)"
    echo -e "${LIGHT_YELLOW}Formats${NC}:  ${VALID_FORMATS[@]}"
    echo -e "${LIGHT_YELLOW}Filters${NC}:  ${VALID_FILTERS[*]}"
    echo -e "${LIGHT_YELLOW}Examples${NC}: $0 -o jpeg"
    echo -e "          $0 -i pdf -o png"
    echo -e "          $0 -i jpg,png -o webp"
    echo -e "          $0 -i pdf -o png -q 85"
    echo -e "          $0 -i pdf -o png -q 85 -f sepia"
    exit 1
}

# Function to convert a string to lowercase (portable)
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Validate extension
is_valid_output_extension() {
    local ext
    ext=$(to_lowercase "$1")  # Convert extension to lowercase
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
            echo -e "${RED}Error:${NC} Invalid extension '$ext'. Supported: ${VALID_FORMATS[*]}"
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
            echo -e "${RED}Error:${NC} Invalid filter '$filter'. Supported: ${VALID_FILTERS[*]}"
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
                echo -e "${RED}Error:${NC} Unsupported filter '$filter'."
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
                jpegoptim --strip-all --strip-iptc --strip-exif --max=85 "$file"
                ;;
            *.png)
                optipng -o7 -strip all "$file"
                pngcrush -brute -strip "$file" "$file"
                ;;
            *.gif)
                gifsicle -O3 --colors 256 --no-comments --minify "$file" -o "$file"
                ;;
            *)
                echo -e "${YELLOW}⚠️  No optimization support for this format"
                ;;
        esac
    fi
}

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
        -opt) OPTIMIZE=true; shift 1 ;;
        -h|--help) usage ;;      # Show help and exit
        *) usage ;;              # Default: Show usage if an invalid option is provided
    esac
done

# Validate output extension
if [[ -z "$OUTPUT_EXT" ]]; then
    echo -e "${RED}Error:${NC} Output extension is required."
    usage
fi

OUTPUT_EXT=$(to_lowercase "$OUTPUT_EXT")  # Convert output extension to lowercase

if ! is_valid_output_extension "$OUTPUT_EXT"; then
    echo -e "${RED}Error:${NC} Invalid output extension '$OUTPUT_EXT'. Supported: ${VALID_FORMATS[*]}"
    exit 1
fi

# Validate filter
if [[ -n "$FILTER" ]]; then
    if ! is_valid_filter "$FILTER"; then
        echo -e "${RED}Error:${NC} Invalid filter '$FILTER'. Supported filters: ${VALID_FILTERS[*]}"
        exit 1
    fi
fi


# Check for magick
if ! command -v magick &> /dev/null; then
    echo -e "${RED}Error:${NC} ImageMagick 'magick' is not installed."
    exit 1
fi

# If input ext not provided, detect all valid images in the directory
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
        echo -e "${YELLOW}⚠️ No image files found in current directory.${NC}"
        exit 0
    fi
else
    IFS=' ,;' read -ra EXT_ARRAY <<< "$(to_lowercase "$INPUT_EXT")"
    for ext in "${EXT_ARRAY[@]}"; do
        if ! is_valid_input_extension "$ext"; then
            echo -e "${RED}Error:${NC} Invalid input extension '$ext'. Supported: ${VALID_FORMATS[*]}"
            exit 1
        fi
    done
fi

# If converting from PDF, check for Ghostscript
if [[ " ${EXT_ARRAY[*]} " == *"pdf"* && "$OUTPUT_EXT" != "pdf" ]]; then
    if ! command -v gs &>/dev/null; then
        echo -e "${RED}Error:${NC} Ghostscript is required for PDF input. Aborting."
        exit 1
    fi
fi

declare -a processed_files=()

# Start conversion
echo -e "${CYAN}🔄 Converting files to .${OUTPUT_EXT} with quality ${QUALITY}...${NC}"
shopt -s nullglob nocaseglob
count=0

for ext in "${EXT_ARRAY[@]}"; do
    for file in Input/*."$ext"; do
        [[ -f "$file" ]] || continue
        input=$(basename "$file" ".${input_ext}")
        output="Output/${input}.${OUTPUT_EXT}"
        # Check if the base filename already exists in the processed_files array
        if [[ " ${processed_files[@]} " =~ " ${input} " ]]; then
            # If it exists, silently skip this file
            continue
        fi

        # Check if output file already exists
        if [[ -f "$output" ]]; then
            echo -e "${RED}❌ Skipping:${NC} file '$output' already exists."
            processed_files+=("$input")
            continue  # Skip this file and move to the next
        fi
        # Apply the filter if specified
        filter_cmds=""
        if [[ -n "$FILTER" ]]; then
            echo -e "${YELLOW}⚙️  Applying filter(s):${NC} $FILTER"
            filter_cmds=$(apply_filters "$FILTER")
        fi

        # Default conversion if no filter or enhancement is provided
        echo -e "⚙️  ${YELLOW}Converting:${NC} \"$file\" → \"$output\""
        if magick "$file" $filter_cmds "$output"; then
            # Apply optimization if the flag is set
            if $OPTIMIZE; then
                echo -e "${YELLOW}⚙️  Applying Optimizations ${NC}"
                apply_optimizations "$output"
            fi
            echo -e "${GREEN}✅ Converted:${NC} $file → $output"
            ((count++))
            if [[ $auto_remove = "true" ]]; then
                echo -e "${GREEN}✅ Removed Source File:${NC} $file → $output"
                rm "$file"
            fi
        else
            echo -e "${RED}❌ Failed:${NC} $file"
        fi
    done
done

if [[ $count -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No matching files were converted.${NC}"
else
    echo -e "${GREEN}🎉 Done! Converted $count file(s).${NC}"
fi

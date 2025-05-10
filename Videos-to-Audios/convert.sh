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

# Validate video and audio container types
VALID_VIDEO_EXTS=("mp4" "mkv" "avi" "mov" "flv" "webm")
VALID_AUDIO_FORMATS=("mp3" "aac" "wav" "flac" "ogg")
auto_remove=false

# Help message
usage() {
    echo -e "${CYAN}Usage${NC}:   $0 [-i input_ext] -o input_ext [-c audio_codec] [-b bitrate] [directory]"
    echo -e "\n${LIGHT_YELLOW}Remove${NC}:   Auto remove source images after conversion (default: false)"
    echo -e "${LIGHT_YELLOW}Video Formats${NC}: ${VALID_VIDEO_EXTS[@]}"
    echo -e "${LIGHT_YELLOW}Audio Formats${NC}: ${VALID_AUDIO_FORMATS[*]}"
    echo -e "${LIGHT_YELLOW}Examples${NC}: $0 -v mp4"
    echo -e "          $0 -i mp4 -o mp3"
    echo -e "          $0 -i mp4 -o mp3"
    echo -e "          $0 -i mp4 -o mp3 -b 192k"
    echo -e "          $0 -i mp4 -o mp3 -c libmp3lame"
    exit 1
}


# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        i) VIDEO_EXT="$2" shift 2 ;;
        o) AUDIO_EXT="$2" shift 2 ;;
        c) AUDIO_CODEC="$2" shift 2 ;;
        b) BITRATE="$2" shift 2 ;;
        -r|--remove)
            auto_remove="$2"
            shift 2
            ;;
        -h|--help) usage ;;      # Show help and exit
        *) usage ;;              # Default: Show usage if an invalid option is provided
    esac
done

# Get the directory (default to current if not supplied)

if [[ ! " ${VALID_VIDEO_EXTS[@]} " =~ " ${VIDEO_EXT} " ]]; then
    echo -e "${RED}❌ Error:${NC} Invalid video format. Supported formats: ${VALID_VIDEO_EXTS[*]}"
    exit 1
fi

if [[ ! " ${VALID_AUDIO_FORMATS[@]} " =~ " ${AUDIO_EXT} " ]]; then
    echo -e "${RED}❌ Error:${NC} Invalid audio format. Supported formats: ${VALID_AUDIO_FORMATS[*]}"
    exit 1
fi

TARGET_DIR="Input"

# Loop through all video files in the specified directory
shopt -s nullglob
echo -e "${CYAN}Starting the conversion process...${NC}"

count=0
for file in "$TARGET_DIR"/*; do
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}⚙️ Converting:${NC} $file → ${AUDIO_EXT}"
        # Build the output audio filename
        output_file="Output/$(basename -- "${file%.*}").${AUDIO_EXT}"
        # output_file="${file%.*}.$AUDIO_EXT"

        # Run the conversion with the specified audio codec and bitrate
        if ffmpeg -i "$file" -vn -acodec "$AUDIO_CODEC" -ab "$BITRATE" "$output_file"; then
            echo -e "${GREEN}✅ Converted:${NC} $file → $output_file"
            count=$((count + 1))
            if [[ $auto_remove  = "true" ]]; then
                echo -e "${GREEN}✅ Removed Source File:${NC} $file → $output"
                rm $file
            fi
        else
            echo -e "${RED}❌ Failed:${NC} Conversion failed for $file"
        fi
    fi
done

if [[ $count -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No files were converted.${NC}"
else
    echo -e "${GREEN}🎉 Conversion complete. $count file(s) converted.${NC}"
fi

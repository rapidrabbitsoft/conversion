#!/bin/bash

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
LIGHT_YELLOW='\033[0;33m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Supported formats
VALID_EXTENSIONS=("mp4" "m4v" "f4v" "mov" "avi" "ogv" "mkv" "wmv" "ts" "vob" "m2ts" "flv" "webm" "mpeg" "mpg" "3gp" "wmv")

# Parse arguments
AUDIO_RANGE=""
VIDEO_RANGE=""
SUBTITLE_RANGE=""
OUTPUT_EXT="mp4"  # Default to mp4
SHOW_PROGRESS_ONLY=false
POSITIONAL=()

useage() {
  echo -e "${CYAN}Usage:${NC} $0 [options]"
  echo -e "${LIGHT_YELLOW}Options:${NC}"
  echo -e "  -a, --audio TRACKS Select audio tracks (e.g. 0 or 0-1), (default: all tracks)"
  echo -e "  -v, --video TRACKS Select video tracks (e.g. 0 or 0-1), (default: all tracks)"
  echo -e "  -s, --subtitles TRACKS Select subtitle tracks (e.g. 0 or 0-1), (default: all tracks)"
  echo -e "  -e, --ext EXTENSION Set the output file extension (default: mp4)"
  echo -e "  -p, --progress Show only progress (percentage) and suppress FFmpeg output"
  echo -e "  -h, --help  Show this help message"
  echo -e "${LIGHT_YELLOW}Example:${NC}"
  echo -e "  $0"
  echo -e "  $0 -a 0-1 -v 0-0"
  echo -e "  $0 -a 0-1 -v 0-0 -e mp4"
}

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
    -h|--help)
      useage
      exit 0
      ;;
    -p|--progress)
      SHOW_PROGRESS_ONLY=true
      shift
      ;;
    -*)
      echo -e "${RED}Unknown option $1${NC}"
      useage
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"
TARGET_DIR="$(pwd)"

if [[ -z "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Directory path required${NC}"
  useage
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Directory not found: $TARGET_DIR${NC}"
  exit 1
fi

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
    # Single track
    map_args+=("-map" "0:${type}:${range}")
  else
    # Map all by type
    map_args+=("-map" "0:${type}")
  fi

  echo "${map_args[@]}"
}

# Function to calculate and display progress
show_progress() {
  local duration="$1"
  local current_time="$2"

  # Convert timestamps to seconds
  IFS=':' read -r hh mm ss <<< "$current_time"
  ss_frac=$(echo "$ss" | awk '{printf "%.2f", $1}')
  current_sec=$(echo "$hh * 3600 + $mm * 60 + $ss_frac" | bc)

  percent=$(echo "$current_sec / $duration * 100" | bc -l)
  printf "\r${YELLOW}⚠️  Progress${NC}: %5.1f%%" "$percent"
}


# Get duration in seconds using ffprobe
get_duration() {
  local input_file="$1"
  ffprobe -v error -select_streams v:0 -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$input_file"
}

echo -e "${CYAN}🔄 Processing Videos${NC}"

existing_files=()

shopt -s nullglob
for file in "$TARGET_DIR"/*; do
  ext="${file##*.}"
  ext_lc=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  if [[ " ${VALID_EXTENSIONS[*]} " =~ " $ext_lc " ]]; then
    filename=$(basename -- "$file")
    output="${file%.*}.${OUTPUT_EXT}"

    # Check if the output file already exists in the array
    if [[ " ${existing_files[@]} " =~ " ${output} " ]]; then
      continue  # Skip this file and move on to the next one
    fi

    # Check if output file already exists
    if [[ -f "$output" ]]; then
      echo -e "${RED}❌ Error:${NC} '$(basename "$output")' already exists. Skipping."
      existing_files+=("$output")
      continue
    fi

    echo -e "${YELLOW}⚠️  Processing:${NC} $filename → $(basename "$output")"

    # Get duration of the input video file
    duration=$(get_duration "$file")

    # Special handling for wma files
    if [[ "$ext_lc" == "wma" ]]; then
      echo -e "${YELLOW}⚠️ Transcoding WMV to MP4...${NC}"

      # Set transcoding command for WMV file (transcoding video/audio)
      ffmpeg -i "$file" -c:v libx264 -crf 23 -c:a aac -b:a 192k "$output" -nostdin \
        && echo -e "${GREEN}✅ Conversion Complete: $output${NC}" \
        || echo -e "${RED}❌ Failed: $output${NC}"
    else
      # For other files, mux without re-encoding
      audio_args=()
      video_args=()
      subtitle_args=()

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

      # Run ffmpeg with live progress inline
      if [[ "$SHOW_PROGRESS_ONLY" == true ]]; then
        ffmpeg -hide_banner -y -i "$file" \
          "${video_args[@]}" "${audio_args[@]}" "${subtitle_args[@]}" \
          -c copy -strict -2 "$output" 2>&1 | \
          while IFS= read -r line; do
            if [[ $line =~ time=([0-9:.]+) ]]; then
              cur_time="${BASH_REMATCH[1]}"
              show_progress "$duration" "$cur_time"
            fi
          done
          echo -e "\n${CYAN}✅ Conversion Complete${NC}"
      else
        # Standard output
        ffmpeg -hide_banner -y -i "$file" \
          "${video_args[@]}" "${audio_args[@]}" "${subtitle_args[@]}" \
          -c copy -strict -2 "$output"
        echo -e "${CYAN}✅ Conversion Complete${NC}"
      fi
    fi
  fi
done

echo -e "${GREEN}🎉 Video Conversion Done!${NC}"

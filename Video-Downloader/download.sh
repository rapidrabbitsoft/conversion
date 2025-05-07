#!/bin/bash

# Color codes for prettifying the output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_YELLOW='\033[0;33m'
CYAN='\033[1;36m'
NC='\033[0m'  # No Color

# Default values
URLS=()

# Display usage
usage() {
    echo -e "${CYAN}Usage:${NC} $0 [-u url1,url2,...]"
    echo -e "       -h, --help  Display this help message"
    exit 1
}

# Parse flags
while [[ "$1" == -* ]]; do
    case "$1" in
        -u)
            IFS=',' read -ra URLS <<< "$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *) usage ;;
    esac
done

# If no URLs are provided via flags, check for downloads.txt file in the current directory
if [[ ${#URLS[@]} -eq 0 ]]; then
    if [[ -f "downloads.txt" ]]; then
        # Read each line from the file into the URLS array
        while IFS= read -r line; do
            echo "$line"
            URLS+=("$line")
        done < "downloads.txt"
    else
        echo -e "${RED}Error:${NC} No valid URLs supplied for downloading1"
        exit 1
    fi
fi

# Ensure that we have a valid list of URLs
if [[ ${#URLS[@]} -eq 0 ]]; then
    echo -e "${RED}Error:${NC} No valid URLs supplied for downloading2"
    exit 1
fi

# Start downloading
echo -e "${CYAN}🔄 Starting to download videos${NC}"

failed=false
# Loop through each URL and download the video
for url in "${URLS[@]}"; do
    echo -e "${YELLOW}⬇️  Downloading:${NC} $url"

    if yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" "$url"; then
        echo -e "${GREEN}✅ Downloaded:${NC} $url"
    else
        echo -e "${RED}❌ Donwload Failed:${NC} $url"
        failed=true
    fi
done

if [ "$failed" = true ]; then
    echo -e "${RED}❌ Some downloads failed.${NC}"
else
    echo -e "${GREEN}All downloads successful.${NC}"
    rm -f downloads.txt
    touch downloads.txt
    echo -e "${CYAN}🎉 downloads.txt has been reset.${NC}"
fi

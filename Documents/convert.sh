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

# Help function to display usage
usage() {
    echo -e "${CYAN}Usage:${NC} $0 [-i input_ext] [-o output_ext]"
    echo -e "${LIGHT_YELLOW}Options:${NC}"
    echo -e "  -i  input_ext    : Specify the input file extension (default: md)"
    echo -e "  -o  output_ext   : Specify the output file extension (default: docx)"
    echo -e "  -r  auto_remove  : Auto Remove file on successful conversion (default: true)"
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
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option: $1"
            usage
            ;;
    esac
done

# Find files with the specified input extension
IFS=$'\n' files=($(find "Input/" -type f -name "*.${input_ext}"))
if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No ${input_ext} files found in the directory.${NC}"
    exit 0
fi

for file in "${files[@]}"; do
    file_name=$(basename "$file" ".${input_ext}")
    dir_name=$(dirname "$file")
    echo -e "${YELLOW}⚠️  Converting${NC}"
    if pandoc "$file" -o "Output/${file_name}.${output_ext}"; then
        echo -e "${GREEN}✅ Converted:${NC} $(basename "$file") → $(basename "$file_name").${output_ext}"
        if [[ $auto_remove  = "true" ]]; then
            echo -e "${GREEN}✅ Removed Source File:${NC} $file → $output"
            rm $file
        fi
    else
        echo -e "${RED}❌ Conversion failed:${NC} $(basename "$file")"
    fi
done

echo -e "${GREEN}🎉 All conversions complete.${NC}"

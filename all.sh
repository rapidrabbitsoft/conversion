#!/bin/bash

# List of subdirectories with convert.sh
SUBDIRS=("Images" "Documents" "Videos" "Videos-to-Audios")

# Function to get convert flag mapping
# This replaces the associative array that's not supported in Bash 3.2
get_convert_flag() {
    local subdir="$1"
    local flag="$2"
    
    case "$subdir" in
        "Images")
            case "$flag" in
                "quality") echo "-q" ;;
                "output_ext") echo "-o" ;;
                "input_ext") echo "-i" ;;
                "filter") echo "-f" ;;
                "auto_remove") echo "-r" ;;
                "jobs") echo "-j" ;;
                "opt") echo "-opt" ;;
                *) echo "" ;;
            esac
            ;;
        "Documents")
            case "$flag" in
                "input_ext") echo "-i" ;;
                "output_ext") echo "-o" ;;
                "auto_remove") echo "-r" ;;
                "jobs") echo "-j" ;;
                *) echo "" ;;
            esac
            ;;
        "Videos")
            case "$flag" in
                "audio") echo "-a" ;;
                "video") echo "-v" ;;
                "subtitles") echo "-s" ;;
                "ext") echo "-e" ;;
                "progress") echo "-p" ;;
                "jobs") echo "-j" ;;
                "auto_remove") echo "-r" ;;
                *) echo "" ;;
            esac
            ;;
        "Videos-to-Audios")
            case "$flag" in
                "input") echo "-i" ;;
                "output") echo "-o" ;;
                "codec") echo "-c" ;;
                "bitrate") echo "-b" ;;
                "jobs") echo "-j" ;;
                "auto_remove") echo "-r" ;;
                *) echo "" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

# Usage/help
usage() {
    echo "Usage: $0 [--images-flag value ...] [--documents-flag value ...] [--videos-flag value ...] [--videos-to-audios-flag value ...]"
    echo "\nExamples:"
    echo "  $0 --images-quality 90 --documents-auto_remove true --videos-ext mkv --videos-to-audios-bitrate 320k"
    echo "\nSupported flags:"
    echo "  Images: quality, output_ext, input_ext, filter, auto_remove, jobs, opt"
    echo "  Documents: input_ext, output_ext, auto_remove, jobs"
    echo "  Videos: audio, video, subtitles, ext, progress, jobs, auto_remove"
    echo "  Videos-to-Audios: input, output, codec, bitrate, jobs, auto_remove"
    echo "\nFlags are passed as --<subdir>-<flag> <value> (use underscores for multi-word flags)."
    echo "\nThis script will run each convert.sh with the specified flags."
    exit 1
}

# Parse args
# For each subdir, build an array of args
for sub in "${SUBDIRS[@]}"; do
    # Convert subdir name to valid variable name (replace dashes with underscores)
    sub_var=$(echo "$sub" | tr '-' '_')
    eval "ARGS_${sub_var}=()"
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --*)
            # Remove leading --
            flag="${1:2}"
            # Split at first dash
            subdir_part="${flag%%-*}"
            flag_part="${flag#*-}"
            # Normalize subdir name (dashes/underscores to underscores, lowercase)
            subdir_key=$(echo "$subdir_part" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
            flag_key=$(echo "$flag_part" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
            
            # Get the convert flag using our function
            convert_flag=$(get_convert_flag "$subdir_key" "$flag_key")
            if [[ -z "$convert_flag" ]]; then
                echo "Unknown flag: --$flag (for $subdir_key)"
                usage
            fi
            
            # Find the actual subdir name (case-insensitive match)
            subdir_real=""
            for s in "${SUBDIRS[@]}"; do
                s_lower=$(echo "$s" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
                if [[ "$s_lower" == "$subdir_key" ]]; then
                    subdir_real="$s"
                    break
                fi
            done
            
            if [[ -z "$subdir_real" ]]; then
                echo "Unknown subdir: $subdir_key"
                usage
            fi
            
            # Convert subdir name to valid variable name
            subdir_var=$(echo "$subdir_real" | tr '-' '_')
            
            # If the flag is a boolean (like -opt or -p), check if next arg is a value or another flag
            if [[ "$convert_flag" == "-opt" || "$convert_flag" == "-p" ]]; then
                eval "ARGS_${subdir_var}+=(\"$convert_flag\")"
                shift 1
            else
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "Missing value for flag: --$flag"
                    usage
                fi
                eval "ARGS_${subdir_var}+=(\"$convert_flag\" \"$2\")"
                shift 2
            fi
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

# Run each convert.sh with its args
for sub in "${SUBDIRS[@]}"; do
    script="$sub/convert.sh"
    subdir_var=$(echo "$sub" | tr '-' '_')
    eval "args=(\"\${ARGS_${subdir_var}[@]}\")"
    if [[ -f "$script" ]]; then
        echo "Running $script ${args[*]}"
        bash "$script" "${args[@]}"
    else
        echo "No convert.sh found in $sub, skipping."
    fi
done 
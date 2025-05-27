# Video to Audio Converter

A powerful script for extracting audio from video files with support for multiple formats, parallel processing, and detailed logging.

## Features

- Extracts audio from various video formats
- Supports multiple audio formats (MP3, WAV, AAC, etc.)
- Parallel processing for faster conversions
- Colored terminal output for better visibility
- Detailed logging with timestamps
- Automatic source file removal option
- Progress tracking and error handling
- Customizable audio quality and codec

## Usage

```bash
./convert.sh --help
# Basic conversion (mp4 to mp3)
./convert.sh -i mp4 -o mp3

# Set custom bitrate
./convert.sh -i mp4 -o mp3 -b 320k

# Use specific audio codec
./convert.sh -i mp4 -o mp3 -c libmp3lame

# Enable parallel processing
./convert.sh -i mp4 -o mp3 -j 4

# Remove source files after conversion
./convert.sh -i mp4 -o mp3 -r true
```

### Options

- `-i, --input`: Input video extension (default: mp4)
- `-o, --output`: Output audio extension (default: mp3)
- `-c, --codec`: Audio codec to use (default: libmp3lame)
- `-b, --bitrate`: Audio bitrate (default: 192k)
- `-j, --jobs`: Number of parallel jobs (default: 2)
- `-r, --remove`: Remove source files after conversion (default: false)
- `-h, --help`: Show help message

### Supported Video Formats

- MP4
- MKV
- AVI
- MOV
- FLV
- WEBM

### Supported Audio Formats

- MP3
- AAC
- WAV
- FLAC
- OGG

### Installation Requirements

* **Ubuntu/Debian**: `sudo apt install ffmpeg`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install ffmpeg`
* **macOS**: `brew install ffmpeg`
* **Windows**: Download binaries and add them to your `PATH`
* **Arch Linux/Manjaro**: `sudo pacman -Syu ffmpeg`

### Logging

The script provides detailed logging with color-coded output:
- 🔴 ERROR: Red
- 🟡 WARNING: Yellow
- 🟢 SUCCESS: Green
- 🔵 INFO: Cyan

Logs are saved to `conversion.log` for future reference.

## Contributing

Feel free to submit issues and enhancement requests!

TODO:

* Validate audio codecs
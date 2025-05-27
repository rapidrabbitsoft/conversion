# Video Converter

A powerful script for converting videos between formats with support for track selection, parallel processing, and detailed logging.

## Features

- Converts between various video formats (MP4, AVI, MOV, etc.)
- Select specific audio, video, and subtitle tracks
- Parallel processing for faster conversions
- Colored terminal output for better visibility
- Detailed logging with timestamps
- Automatic source file removal option
- Progress tracking and error handling
- Special handling for WMV files

## Usage

```bash
./convert.sh --help
# Basic conversion (all tracks)
./convert.sh

# Select specific tracks
./convert.sh -a 0-1              # Audio tracks 0-1
./convert.sh -v 0-1              # Video tracks 0-1
./convert.sh -a 0-1 -v 1-2       # Audio tracks 0-1 and video tracks 1-2
./convert.sh -a 0-1 -v 1-2 -s 0-12  # Audio, video, and subtitle tracks

# Show only progress
./convert.sh -p

# Enable parallel processing
./convert.sh -j 4

# Remove source files after conversion
./convert.sh -r true
```

### Options

- `-a, --audio`: Select audio tracks (e.g., 0 or 0-1)
- `-v, --video`: Select video tracks (e.g., 0 or 0-1)
- `-s, --subtitles`: Select subtitle tracks (e.g., 0 or 0-1)
- `-e, --ext`: Set output file extension (default: mp4)
- `-p, --progress`: Show only progress percentage
- `-j, --jobs`: Number of parallel jobs (default: 2)
- `-r, --remove`: Remove source files after conversion (default: false)
- `-h, --help`: Show help message

### Supported Formats

- MP4
- M4V
- F4V
- MOV
- AVI
- OGV
- MKV
- WMV
- TS
- VOB
- M2TS
- FLV
- WEBM
- MPEG
- MPG
- 3GP

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

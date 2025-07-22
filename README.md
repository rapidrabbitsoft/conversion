# File Conversion Toolkit

A comprehensive set of tools for converting various file formats. Simply drop your files into the appropriate folder, and they will be automatically converted to the desired format.

## Available Converters

### 📄 Documents
- Converts between various document formats (PDF, DOCX, TXT, etc.)
- Supports batch processing
- Maintains formatting and structure

### 🖼️ Images
- Converts between common image formats (JPG, PNG, WEBP, etc.)
- Includes image optimization features
- Supports filters and basic image editing
- Batch processing available

### 📥 Video Downloader
- Downloads YouTube videos
- Supports various quality options
- Batch download capability
- Custom output format selection

### 🎥 Videos
- Converts between video formats (MP4, AVI, MOV, etc.)
- Supports various codecs
- Quality preservation options
- Batch processing available

### 🎵 Videos to Audio
- Extracts audio from video files
- Supports multiple audio formats (MP3, WAV, AAC, etc.)
- Maintains audio quality
- Batch conversion support

## Usage

1. Navigate to the desired converter folder
2. Drop your files into the folder
3. Wait for the conversion to complete
4. Find your converted files in the output directory

## Batch Conversion: all.sh

The `all.sh` script allows you to run all available `convert.sh` scripts in subdirectories with custom flags for each. This is useful for batch processing across multiple types (images, documents, videos, etc.) in one command.

### Usage

```bash
./all.sh [--images-flag value ...] [--documents-flag value ...] [--videos-flag value ...] [--videos-to-audios-flag value ...]
```

#### Example:
```bash
./all.sh --images-quality 90 --documents-auto_remove true --videos-ext mkv --videos-to-audios-bitrate 320k
```

#### Flag Convention
- Flags are passed as `--<subdir>-<flag> <value>`
- Use underscores for multi-word flags (e.g., `--videos-to-audios-bitrate`)
- Each flag is routed to the correct subdirectory’s `convert.sh` script

### Supported Flags

| Subdirectory         | Flag            | Example Flag                | Description                                      |
|---------------------|-----------------|-----------------------------|--------------------------------------------------|
| **Images**          | quality         | --images-quality 90         | Output image quality (1-100)                     |
|                     | output_ext      | --images-output_ext png     | Output file extension                            |
|                     | input_ext       | --images-input_ext jpg      | Input file extension(s)                          |
|                     | filter          | --images-filter grayscale   | Image filter(s) to apply                         |
|                     | auto_remove     | --images-auto_remove true   | Remove source images after conversion            |
|                     | jobs            | --images-jobs 4             | Number of parallel jobs                          |
|                     | opt             | --images-opt                | Enable optimization (no value needed)            |
| **Documents**       | input_ext       | --documents-input_ext md    | Input file extension                             |
|                     | output_ext      | --documents-output_ext pdf  | Output file extension                            |
|                     | auto_remove     | --documents-auto_remove true| Remove source files after conversion             |
|                     | jobs            | --documents-jobs 2          | Number of parallel jobs                          |
| **Videos**          | audio           | --videos-audio 0-1          | Select audio tracks                              |
|                     | video           | --videos-video 0-0          | Select video tracks                              |
|                     | subtitles       | --videos-subtitles 0        | Select subtitle tracks                           |
|                     | ext             | --videos-ext mkv            | Output file extension                            |
|                     | progress        | --videos-progress           | Show only progress (no value needed)             |
|                     | jobs            | --videos-jobs 2             | Number of parallel jobs                          |
|                     | auto_remove     | --videos-auto_remove true   | Remove source videos after conversion            |
| **Videos-to-Audios**| input           | --videos-to-audios-input mp4| Input video extension                            |
|                     | output          | --videos-to-audios-output mp3| Output audio extension                           |
|                     | codec           | --videos-to-audios-codec libmp3lame| Audio codec to use                     |
|                     | bitrate         | --videos-to-audios-bitrate 320k| Audio bitrate                              |
|                     | jobs            | --videos-to-audios-jobs 2   | Number of parallel jobs                          |
|                     | auto_remove     | --videos-to-audios-auto_remove true| Remove source files after conversion     |

- For boolean flags (like `--images-opt` or `--videos-progress`), just include the flag (no value needed).
- Run `./all.sh --help` for a summary of supported flags and usage.

## Requirements

- Python 3.8 or higher
- Required Python packages (automatically installed):
  - ffmpeg-python
  - Pillow
  - PyPDF2
  - pytube

## Contributing

Feel free to submit issues and enhancement requests!

# Image Converter

A powerful script for converting and optimizing images with support for filters, parallel processing, and detailed logging.

## Features

- Converts between various image formats (JPG, PNG, WEBP, etc.)
- Image optimization for smaller file sizes
- Multiple image filters (grayscale, sepia, blur, etc.)
- Parallel processing for faster conversions
- Colored terminal output for better visibility
- Detailed logging with timestamps
- Automatic source file removal option
- Progress tracking and error handling

## Usage

```bash
./convert.sh --help
# Basic conversion (default: to jpeg)
./convert.sh -o jpeg

# Convert specific formats
./convert.sh -i pdf -o png
./convert.sh -i jpg,png -o webp

# Set quality and apply filter
./convert.sh -i pdf -o png -q 85 -f sepia

# Enable optimization and parallel processing
./convert.sh -i pdf -o png -opt -j 4

# Remove source files after conversion
./convert.sh -i pdf -o png -r true
```

### Options

- `-i, --input`: Input file extension(s) (comma-separated)
- `-o, --output`: Output file extension (required)
- `-q, --quality`: Output quality (1-100, default: 100)
- `-f, --filter`: Apply image filter(s) (comma-separated)
- `-j, --jobs`: Number of parallel jobs (default: 4)
- `-r, --remove`: Remove source files after conversion (default: true)
- `-opt`: Enable optimization
- `-h, --help`: Show help message

### Supported Formats

- JPG/JPEG
- PNG
- GIF
- BMP
- HEIC
- WEBP
- PDF
- TIFF
- RAW (CR2, NEF, ARW)

### Supported Filters

- Grayscale
- Sepia
- Invert
- Blur
- Sharpen
- Contrast
- Vignette
- Charcoal
- Sketch
- Spread
- Swirl
- Polaroid
- Oil-paint
- Normalize
- Equalize
- Denoise

### Installation Requirements

* **Ubuntu/Debian**: `sudo apt install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler-utils libheif-dev libraw-dev`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler-utils libheif-devel libraw-devel`
* **macOS**: `brew install imagemagick --build-from-source && brew install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler libheif libraw`
* **Windows**: Download binaries and add them to your `PATH`
* **Arch Linux/Manjaro**: `sudo pacman -Syu imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler libheif-dev libraw-dev`

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

* Add the ability to pass through filter options (currently hard-coded)
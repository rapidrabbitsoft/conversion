# Document Converter

A powerful script for converting between various document formats with support for parallel processing and detailed logging.

## Features

- Converts between various document formats (PDF, DOCX, TXT, etc.)
- Parallel processing for faster conversions
- Colored terminal output for better visibility
- Detailed logging with timestamps
- Automatic source file removal option
- Progress tracking and error handling

## Usage

```bash
./convert.sh --help
# Basic conversion (default: md to docx)
./convert.sh

# Specify input and output formats
./convert.sh -i md -o docx

# Enable parallel processing with 4 jobs
./convert.sh -i md -o docx -j 4

# Remove source files after conversion
./convert.sh -i md -o docx -r true
```

### Options

- `-i, --input`: Input file extension (default: md)
- `-o, --output`: Output file extension (default: docx)
- `-j, --jobs`: Number of parallel conversion jobs (default: 4)
- `-r, --remove`: Remove source files after conversion (default: false)
- `-h, --help`: Show help message

### Installation Requirements

* **Ubuntu/Debian**: `sudo apt install pandoc`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install pandoc`
* **macOS**: `brew install pandoc`
* **Windows**: `choco install pandoc`
* **Arch Linux/Manjaro**: `sudo pacman -Syu pandoc`

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
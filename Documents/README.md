# Document Converter

This script attempts to convert between various document types.

## Useage:

~~~bash
./convert.sh --help
# Define the output format. Default: docx
./convert.sh -o docx
./convert.sh -i md -o docx
~~~

### Installation Requirements:

* **Ubuntu/Debian**: `sudo apt install pandoc`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install pandoc`
* **macOS**: `brew install pandoc`
* **Windows**: `choco install pandoc`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu pandoc`


TODO:

* Add the ability to pass through filter options (currently hard-coded)
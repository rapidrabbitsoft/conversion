# Image Converter

This script any image format into another image format and also performs optimizations on the images.

## Useage:

~~~bash
./convert.sh --help
# Define the output format. Default: jpeg
./convert.sh -o jpeg
# Define a comma separated list of input formats. Default: any valid image format.
./convert.sh -i pdf -o png
./convert.sh -i jpg,png -o webp
# Defines the quality to convert the image too
./convert.sh -i pdf -o png -q 85
# Apply a filter
./convert.sh -i pdf -o png -q 85 -f sepia
# Apply image optimizations
./convert.sh -i pdf -o png -opt
~~~

### Installation Requirements:

* **Ubuntu/Debian**: `sudo apt install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler-utils libheif-dev libraw-dev`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler-utils libheif-devel libraw-devel`
* **macOS**: `brew install imagemagick --build-from-source && brew install imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler libheif libraw`
* **Windows**: Download binaries and add them to your `PATH`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu imagemagick jpegoptim optipng pngcrush gifsicle ghostscript poppler libheif-dev libraw-dev`


TODO:

* Add the ability to pass through filter options (currently hard-coded)
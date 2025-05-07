# Video Converter

This script converts videos from one video format to another

## Useage:

~~~bash
./convert.sh --help
# Converts all audio, video, and subtitles to another container
./convert.sh
# Converts audio tracks 0-1
./convert.sh -a 0-1
# Converts video tracks 0-1
./convert.sh -v 0-1
# Converts audio tracks 0-1 and video tracks 1-2
./convert.sh -a 0-1 -v 1-2
# Converts audio tracks 0-1 and video tracks 1-2 and subtitle tracks 0-12
./convert.sh -a 0-1 -v 1-2 -s 0-12
# Only show progress rather than ffmpegs full output
./convert.sh -p

# NOTE: For WMV files, it's better to transcode those formats as they can
# be problematic which is how this script handles such formats.
~~~

### Installation Requirements:

* **Ubuntu/Debian**: `sudo apt install ffmpeg`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf ffmpeg`
* **macOS**: `brew install ffmpeg`
* **Windows**: Download binaries and add them to your `PATH`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu ffmpeg`

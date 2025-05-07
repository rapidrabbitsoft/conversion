# Video to Audio Converter

This script takes any video file and grabs the audio from within and generates an audio file.

## Useage:

~~~bash
./convert.sh --help
# Converts mp4s to mp3
./convert.sh -i mp4 -o mp3
# Sets the bitrate mp3
./convert.sh -i mp4 -o mp3 -b 192k
# Sets the audio codec
./convert.sh -i mp4 -o mp3 -c libmp3lame
~~~

### Installation Requirements:

* **Ubuntu/Debian**: `sudo apt install ffmpeg`
* **CentOS/RHEL/Fedora**: `sudo yum/dnf install ffmpeg`
* **macOS**: `brew install ffmpeg`
* **Windows**: Download binaries and add them to your `PATH`.
* **Arch Linux/Manjaro**: `sudo pacman -Syu ffmpeg`


TODO:

* Validate audio codecs
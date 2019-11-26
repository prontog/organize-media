#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]... INPUT_VID OUTPUT_VID
Script that uses ffmpeg to trancode INPUT_VID so that it is streaming friendly.
Defaults to an average 7Mbps bit rate, coded h265 (HECV) and HD resolution.

Options:
  -b        video bit rate for the OUTPUT_VID in ffmpeg format
  -c        video codec for the OUTPUT_VID in ffmpeg format
  -r        video resolution for the OUTPUT_VID in ffmpeg scaling format
  -h        display this help text and exit

Examples:
$ ${0##*/} 4K_VID.mp4 HD_VID.mp4
$ ${0##*/} -b 2M -c hevc -r 1920x1080 4K_VID.mp4 HD_VID.mp4
EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

BIT_RATE=7M
CODEC=hevc
RESOLUTION=1920x1080
while getopts "hb:c:r:" option
do
	case $option in
        b) BIT_RATE=$OPTARG;;
		c) CODEC=$OPTARG;;
		r) RESOLUTION=$OPTARG;;
		h) usage;;
		*) usage;;
	esac
done
shift $(( $OPTIND - 1 ))

INPUT_VID=$1
if [[ ! -f $INPUT_VID ]]; then
	error INPUT_VID is not a file: $INPUT_VID
fi

OUTPUT_VID=$2

ffmpeg -i $INPUT_VID -vf scale=$RESOLUTION -c:v $CODEC -b:v $BIT_RATE -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a $OUTPUT_VID

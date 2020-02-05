#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]... VIDEO_DIR...
Script that transcodes all videos found in VIDEO_DIRs so that they conform to
some maximum specs. The algorithm is the following:

  if bitrate > BR_THRESHOLD then transcode

Options:
  -b BR_THRESHOLD  max video bit rate for the OUTPUT_VID in ffmpeg format.
                   Defaults to 7M
  -i               replace original video. By default this is disabled
  -h               display this help text and exit

EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

BR_THRESHOLD=7M
REPLACE_ORIG=false
while getopts "hb:r:i" option
do
	case $option in
        b) BR_THRESHOLD=$OPTARG;;
        i) REPLACE_ORIG=true;;
		h) usage;;
		*) usage;;
	esac
done
shift $(( $OPTIND - 1 ))

#set -o errexit
#set -o pipefail

if [[ ${BR_THRESHOLD/*M/M} == "M" ]]; then
    BR_THRESHOLD=$((${BR_THRESHOLD%M} * 1000000))
elif [[ ${BR_THRESHOLD/*K/K} == "K" ]]; then
    BR_THRESHOLD=$((${BR_THRESHOLD%K} * 1000))
fi

for VIDEO_DIR in "$@"; do
    if [[ -z $VIDEO_DIR ]]; then
    	error VIDEO_DIR cannot be empty
    fi

    if [[ ! -d $VIDEO_DIR ]]; then
        echo Skipping "'$VIDEO_DIR'". Not a dir  >&2
        continue
    fi

    find "$VIDEO_DIR" -type f | while read INPUT_VID; do
        echo $INPUT_VID
        TRANSCODE=false

        BIT_RATE=$(mediainfo --Output="Video;%BitRate%" "$INPUT_VID")
        if [[ -z $BIT_RATE ]]; then
            continue
        fi
        if [[ $BIT_RATE -gt $BR_THRESHOLD ]]; then
            TRANSCODE=true
            BIT_RATE=$BR_THRESHOLD
        fi

        INPUT_FORMAT=$(mediainfo --Output="Video;%Format%" "$INPUT_VID")
        OUTPUT_FORMAT=h264
        if [[ $INPUT_FORMAT != AVC ]]; then
            TRANSCODE=true
        fi

        INPUT_EXT=${INPUT_VID##*.}
        OUTPUT_EXT=$INPUT_EXT
        if [[ ${INPUT_EXT,*} != mp4 ]]; then
            TRANSCODE=true
            OUTPUT_EXT=mp4
        fi

        if [[ $TRANSCODE == true ]]; then
            OUTPUT_VID="${INPUT_VID%.*}_tr.${OUTPUT_EXT}"
            echo transcoding "$INPUT_VID" to "$OUTPUT_VID"
            if [[ -f $OUTPUT_VID ]]; then
                echo "$OUTPUT_VID" already exists. Skipping
                continue
            fi

            # For a guarrantied bit rate we need to do a douple pass. see
            # https://trac.ffmpeg.org/wiki/Encode/H.264#AdditionalInformationTips
            if ffmpeg -nostdin -i "$INPUT_VID" -y -c:v $OUTPUT_FORMAT -b:v $BIT_RATE -maxrate $BIT_RATE -bufsize $BIT_RATE -pass 1 -an -f mp4 /dev/null >/dev/null 2>&1 && \
               ffmpeg -nostdin -i "$INPUT_VID" -n -c:v $OUTPUT_FORMAT -b:v $BIT_RATE -maxrate $BIT_RATE -bufsize $BIT_RATE -pass 2 -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a "$OUTPUT_VID" >/dev/null 2>&1; then
                # Clean up two pass logs
                rm ffmpeg2pass*
                if [[ $REPLACE_ORIG == true ]]; then
                    rm "$INPUT_VID"
                    mv "$OUTPUT_VID" "${INPUT_VID%.*}.${OUTPUT_EXT}"
                fi
            else
                echo failed to transcode [error code: $?]. Skipping
            fi
        fi
    done
done

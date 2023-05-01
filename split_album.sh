#!/usr/bin/env bash

# Function to output usage information
usage() {
  cat <<EOF
Usage: ${0##*/} [OPTION]... AUDIO_FILE
Script that splits an audio album using a cue file. It expects the cue file to
have the same name with the AUDIO_FILE

Options:
  -h        display this help text and exit

EOF
  exit 1
}
# Print an error message
error() {
	echo "${0##*/}: $*" >&2
	exit 1
}

while getopts "h" option
do
  case $option in
    h) usage;;
    *) usage;;
  esac
done
shift $(( $OPTIND - 1 ))

if [[ ! -f $1 ]]; then
  error AUDIO_FILE is not a file [$1]
fi

set -o errexit

# Move to the directory of the AUDIO_FILE
cd "$(dirname "$(readlink -f "$1")")"
AUDIO_FILE="$(basename "$1")"

CUE_FILE="${AUDIO_FILE%.*}.cue"
if [[ ! -f $CUE_FILE ]]; then
  error Missing $CUE_FILE file
fi

AUDIO_TYPE="${AUDIO_FILE##*.}"

# Convert to flac if necessary
if [[ $AUDIO_TYPE != flac ]]; then
  ffmpeg -nostdin -i "$AUDIO_FILE" "${AUDIO_FILE/.${AUDIO_TYPE}/.flac}"
  rm "$AUDIO_FILE"
  AUDIO_FILE="${AUDIO_FILE/.${AUDIO_TYPE}/.flac}"
  AUDIO_TYPE=flac
fi

# Rename audio and cue files to avoid cases where the audio file has the exact
# name with a generated track file.
mv "$AUDIO_FILE" _temp.flac
AUDIO_FILE=_temp.flac
mv "$CUE_FILE" _temp.cue
CUE_FILE=_temp.cue

# Split single file
cuebreakpoints "$CUE_FILE" | sed 's/$/0/' | shnsplit -o $AUDIO_TYPE "$AUDIO_FILE"

# # Convert to flac if necessary
# if [[ $AUDIO_TYPE != flac ]]; then
#   find -name 'split-track*' | while read f; do
#     ffmpeg -nostdin -i "$f" "${f/.${AUDIO_TYPE}/.flac}"
#     rm "$f"
#   done
# fi

# Retag split files
cuetag "$CUE_FILE" split-track*flac

# Rename from split-track* to  TRACKNUMBER - TITLE
for f in split-track*flac; do
  TITLE=$(metaflac "$f" --show-tag=TITLE | sed 's/.*=//g')
  if [[ -n $TITLE ]]; then
    TRACKNUMBER=$(metaflac "$f" --show-tag=TRACKNUMBER | sed 's/.*=//g')
    mv "$f" "$(printf %02g $TRACKNUMBER) - ${TITLE}.flac";
  fi
done

# Finally delete original single-album file
rm "$AUDIO_FILE"
rm "$CUE_FILE"

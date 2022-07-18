Organize Media
---

A collection of scripts to help me organize my media files. Mostly used for my
[NextCloudPi](https://github.com/nextcloud/nextcloudpi) installation.

## Organizing for NextCloud

The following scripts find media files from a source dir and **move** them to the
current working dir. If they cannot handle them, they leave them in the source
dir. The files are organized per YEAR and then per MONTH by default. Using the
`-d` they can further be organized per DAY.

Moving your photos using *exiftool*:
```bash
cd /path/where/you/want/to/organize/your/files
./organize_photos.sh /path/to/dir/with/photos/to/organize
# This will move files in YYYY/MM dirs.
```

Moving your audio/video files using *mediainfo*:
```bash
cd /path/where/you/want/to/organize/your/files
./organize_media.sh -d /path/to/dir/with/media/to/organize
# This will move files in YYYY/MM/YYYY_MM_DD dirs.
```

Moving your media files using the datestamp on the filename:
```bash
cd /path/where/you/want/to/organize/your/files
./organize_by_filename.sh /path/with/media/to/organize
# This will move files in YYYY/MM dirs.
```

Making a video streaming friendly using *ffmpeg*:
```bash
# Encode new files with the _tr suffix.
./make_video_streaming_friendly.sh /dir/with/videos
# Inplace encode
./make_video_streaming_friendly.sh -i /dir/with/videos
```

Splitting audio files with cue using *cuetools, shntool and ffmpeg*:
```bash
./split_album.sh AUDIO_FILE
```

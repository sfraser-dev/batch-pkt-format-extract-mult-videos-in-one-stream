A company have their own .pkt video format that weaves the output from 3 cameras into a single video file.

Batch file:

- Takes an "interwoven" NETmc video (.pkt format) and "unweaves" it.
- Uses FFMPEG to split the "interwoven" video.pkt into individual JPEG files.
- Each frame from each camera is appropriately named and numbered.
- FFMPEG used to concatenate each frame from each camera into a distinct "unwoven" video.

Perl file:

- Company .pkt video analysis.
- Uses FFPROBE to look for keyframes (I frames) and report the frequency of their occurance.
    - It is assummed there is a camera change {PORT, CENTRE, STBD} on each I-frame in .pkt videos.
    - Also an attempt at FFMPEG cropping (manual input of co-ordinates) to chop out camera overlay informtion to see if this can be used to determine change of video camera: it wasn't.

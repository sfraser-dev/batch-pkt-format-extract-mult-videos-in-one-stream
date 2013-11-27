#!/usr/bin/perl
# NetMC .pkt video analysis.
# Uses FFPROBE to look for keyframes (I frames) and report the frequency of their occurance.
# It is assummed there is a camera change {PORT, CENTRE, STBD} on each I-frame in .pkt videos.
# Uses FFMPEG cropping (manual input of co-ordinates) to chop out camera overlay informtion.

use strict;
use warnings;
use File::Basename;

# Filename extension manipulation
my $PKT="./mpeg1_3ch.pkt";
my ($FN, $DIRS, $SF) = fileparse($PKT,qr"\..[^.]*$");
my $VIDIN = $FN . '.mpg';
my $VIDCNVRT="vid.m2v";
my $VIDCRP="vidCrop.mpg";
my $VIDCRPEDGE="vidCropEdge.mpg";

# Use "key_frame" from ffprobe to determine camera change (where an I frame is assumed to be a camera change)
# Use ffprobe's scene cut detection method where any value over $THRESH is assumed to be a scene cut (camera change)
system("cp $PKT $VIDIN");
system("ffmpeg -v 0 -y -i $VIDIN -an -c:v copy -sc_threshold 1 $VIDCNVRT");
my $THRESH=0.2;
system("ffprobe -v 0 -show_frames -pretty $VIDCNVRT > ./info.txt");
system("ffprobe -v 0 -show_frames -of compact=p=0 -f lavfi \"movie=$VIDCNVRT,select=gt(scene\\,$THRESH)\" > info.csv");
my $KEYFRMRAT=&analyseInfo;
print "Keyframe ratio is $KEYFRMRAT\n";

# Cropping out the camera overlay information, does this help detemine keyframes? (turns out it doesn't)
system("ffmpeg -v 0 -y -i $VIDIN -vf \"crop=50:15:280:260\" -an $VIDCRP");
system("ffmpeg -v 0 -y -i $VIDCRP -vf 'smartblur,edgedetect=low=0.1:high=0.4' $VIDCRPEDGE");
system("ffprobe -v 0 -show_frames -pretty $VIDCRPEDGE > ./infoCropEdge.txt");


sub analyseInfo {
    my $INFOFILE = 'info.txt';
    open my $INFO, $INFOFILE or die "Could not open $INFOFILE: $!";
    my $KF0="key_frame=0";
    my $KF1="key_frame=1";
    my $KF_COUNT=0;
    my $KF0_COUNT=0;
    my $KF1_COUNT=0;
    my $RATIO=0;
    while (my $LINE = <$INFO>) {
        chomp $LINE;
        if ($LINE =~ m/$KF0/) {
            $KF_COUNT++;
            $KF0_COUNT++;
            #print "$LINE count=$KF0_COUNT\n";
        }
        if ($LINE =~ m/$KF1/) {
            $KF_COUNT++;
            $KF1_COUNT++;
            #print "$LINE count=$KF1_COUNT\n";
        }
    }
    #print "KF_COUNT = $KF_COUNT\n";
    $RATIO = $KF_COUNT / $KF1_COUNT;
    #print "Keyframe ratio is $RATIO\n";
    close $INFOFILE;
    return $RATIO;
}

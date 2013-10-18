#!/usr/bin/perl

use strict;
use warnings;

my $VIDIN="../mpeg1_3ch.mpg";
my $VIDCNVRT="vid.m2v";
my $VIDCRP="vidCrop.mpg";
my $VIDCRPEDGE="vidCropEdge.mpg";

system("ffmpeg -v 0 -y -i $VIDIN -an -c:v copy $VIDCNVRT");
system("ffprobe -v 0 -show_frames -pretty $VIDCNVRT > ./info.txt");
system("ffprobe -v 0 -show_frames -of compact=p=0 -f lavfi \"movie=$VIDCNVRT,select=gt(scene\\,.2)\" > info.csv");
my $KEYFRMRAT=&analyseInfo;
print "Keyframe ratio is $KEYFRMRAT\n";
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

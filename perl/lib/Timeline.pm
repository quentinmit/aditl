package Timeline;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	     defaultOptions
	     makeTimeline
	     makeSmallTimeline
	     );

use lib "./";

use POSIX;
use Imager;
use strict;

#public routine...expects an aoptions reference (see below).
#only generates the banded timeline picture....no lines.
sub makeSmallTimeline {
    my $ref = shift;
    my %options = %$ref;

    #derived options
    $options{numberEvents} = int(($options{endTime} - $options{startTime}) / $options{eventWidth});
    $options{pixelsPerEvent} = ceil(($options{timelineWidth} / $options{numberEvents}));
    $options{actualTimelineWidth} = $options{timelineWidth}; #$options{pixelsPerEvent} * $options{numberEvents};

    $options{totalWidth} = $options{actualTimelineWidth};

########## End of Options

    my $timeline = makeTimelineBox(\%options);

    my $output = Imager->new(xsize => $options{totalWidth},
			     ysize => $options{timelineHeight},
			     channels => 3);

    $output->paste(left => 0,
		   top => 0,
		   img => $timeline);

    $output->write(file=>$options{outputFile},
		   type=>"jpeg",
		   jpegquality => $options{jpegQuality}) or die $timeline->errstr;
}


#public routine...expects an options reference (see below).
sub makeTimeline {
    my $ref = shift;
    my %options = %$ref;

    my $numIncludedImages = 0;
    foreach(@{$options{imageData}}) {
	if($_->{included} == 1) {
	    $numIncludedImages++;
	}
    }
    

#derived options
    $options{totalWidth} = $options{imageWidth} * $numIncludedImages;
    $options{numberEvents} = int(($options{endTime} - $options{startTime}) / $options{eventWidth});
    $options{pixelsPerEvent} = int(($options{timelineWidth} / $options{numberEvents}));
    $options{actualTimelineWidth} = $options{pixelsPerEvent} * $options{numberEvents};

    if($options{totalWidth} < $options{actualTimelineWidth}) {
	$options{totalWidth} = $options{actualTimelineWidth};
    }
    
    $options{timelineStartX} = int(($options{totalWidth} - $options{actualTimelineWidth}) / 2);

########## End of Options

    my $timeline = makeTimelineBox(\%options);
    my $lines = makeLines(\%options);

    my $output = Imager->new(xsize => $options{totalWidth},
			     ysize => $options{timelineHeight} + $options{lineHeight},
			     channels => 3);

    $output->box(color => $options{linesBgColor},
		 xmin => 0,
		 ymin => 0,
		 xmax => $options{totalWidth},
		 ymax => $options{timelineHeight} + $options{lineHeight},
		 filled => 1);

    $output->paste(left => 0,
		   top=>0,
		   img => $lines);

    $output->paste(left => $options{timelineStartX},
		   top => $options{lineHeight},
		   img => $timeline);

    $output->write(file=>$options{outputFile},
		   type=>"jpeg",
		   jpegquality => $options{jpegQuality}) or die $timeline->errstr;
}

sub makeTimelineBox {
    my $ref = shift;
    my %options = %$ref;

    my @imageFiles;;
    my @imageTimes;

    my @imageData = @{$options{imageData}};
    foreach(@imageData) {
	push(@imageFiles, $_->{filename});
	push(@imageTimes, $_->{time});
    }
    
#load and scale the images;
    my @images;
    for(my $i = 0; $i < scalar(@imageFiles); $i++) {
	#print $imageFiles[$i] . "\n";
	my $img = Imager->new();
	$img->read(file => $imageFiles[$i], type => "jpeg")
	    or die "Cannot read image $imageFiles[$i]: ", $img->errstr;
	$img = $img->scaleY(pixels => $options{timelineHeight});
	$img = $img->scaleX(pixels => $options{pixelsPerEvent});
	$images[$i] = $img;
	#$img->write(file => "image.jpg",
	#	    type => "jpeg");
	
    }

    my $currentStartTime = $options{startTime};
    my $currentEndTime = $options{startTime} + $options{eventWidth} + 1;
    my $timelineImage = Imager->new(xsize => $options{pixelsPerEvent} * $options{numberEvents},
				    ysize => $options{timelineHeight},
				    channels => 3);
    
    $timelineImage->box(color => $options{timelineBgColor},
			xmin => 0,
			ymin => 0,
			xmax => $options{pixelsPerEvent} * $options{numberEvents},
			ymax => $options{timelineHeight},
			filled => 1);

    my $xposition = 0;
    for(my $i = 0; $i < $options{numberEvents}; $i++) {
	#print "working on event $i\n";
	my @currentImages;
	while(scalar(@imageTimes) &&
	      $imageTimes[0] >= $currentStartTime &&
	      $imageTimes[0] < $currentEndTime) {
	    push(@currentImages, $images[0]);
	    shift(@images);
	    shift(@imageTimes);
	}

	#@currentImages now contains all the images for this time slot
	#if there is more than one, we just use the first
	if(scalar(@currentImages) > 0) {
	    $timelineImage->paste(left => $xposition,
				  top=>0,
				  img => $currentImages[0]);
	}

	$xposition += $options{pixelsPerEvent};
	$currentStartTime += $options{eventWidth};
	$currentEndTime += $options{eventWidth};
    }

    return $timelineImage;
}

sub makeLines {
    my $ref = shift;
    my %options = %$ref;

    my @imageTimes;
    my @imageData = @{$options{imageData}};
    foreach(@imageData) {
	if($_->{included} == 1) {
	    push(@imageTimes, $_->{time});
	}
    }

    my $img = Imager->new(xsize => $options{totalWidth},
			  ysize => $options{lineHeight},
			  channels => 3);

    $img->box(color => $options{linesBgColor},
	      xmin => 0,
	      ymin => 0,
	      xmax => $options{totalWidth},
	      ymax => $options{lineHeight},
	      filled => 1);



#assume the timeline is centered below the lines image
    my $bottomStartX = $options{timelineStartX};

    my $time;
    my $currentTopX = int($options{imageWidth} / 2);
    my $bottomX;
    foreach(@imageTimes) {
	$time = $_ - $options{startTime} - 1;
	$bottomX = $bottomStartX + int(((int($time / $options{eventWidth})) +.5 ) * $options{pixelsPerEvent});

	$img->line(color => $options{lineColor},
		   x1 => $currentTopX,
		   y1 => 0,
		   x2 => $currentTopX,
		   y2 => $options{upperStraightHeight},
		   aa => 1);

	$img->line(color => $options{lineColor},
		   x1 => $currentTopX,
		   y1 => $options{upperStraightHeight},
		   x2 => $bottomX,
		   y2 => $options{lineHeight} - $options{lowerStraightHeight},
		   aa => 1);
	
	$img->line(color => $options{lineColor},
		   x1 => $bottomX,
		   y1 => $options{lineHeight} - $options{lowerStraightHeight},
		   x2 => $bottomX,
		   y2 => $options{lineHeight},
		   aa => 1);
	$currentTopX += $options{imageWidth};
	
    }

    return $img;
}

#takes a reference to a hashtable that will be
#filled with the default option values.
sub defaultOptions {
    my $options = shift;

#$options->{imageData} must be set by the user.
#reference to list.
#list is list of references to a hash where each
#hash has three keys: file, time, and included. If included is true, then
#the corresponding image is included in the timeline and has lines drawn to it.
#If included is false, then the image is included in the timeline but doesn't
#have lines drawn to it.

    $options->{jpegQuality} = 80;

#width in pixels of the timeline
#timeline may be slightly less wide than this.
    $options->{timelineWidth} = 800;

#width of thumbnail images
    $options->{imageWidth} = 100;

#height in pixels of timeline
    $options->{timelineHeight} = 64;

#height of lines section.
    $options->{lineHeight} = 250;

#number of pixels that the upper straight vertical part of the lines will be
    $options->{upperStraightHeight} = 60;

#same for lower vertical lines
    $options->{lowerStraightHeight} = 20;

#beginning time (in minutes) of timeline
    $options->{startTime} = 0;

#end time (in minutes) of timeline
    $options->{endTime} = 1440;

    $options->{timelineBgColor} = Imager::Color->new(161, 158, 149);
    $options->{linesBgColor} = Imager::Color->new(255, 255, 255);
    $options->{lineColor} = Imager::Color->new(255, 169, 99);

#width in minutes of events
    $options->{eventWidth} = 10;

    $options->{outputFile} = "timeline.jpg";
}
1

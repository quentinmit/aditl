package Colors;

require Exporter;
@ISA = qw(Exporter);

use lib "/usr/local/aditl2/perl/lib";

use Imager;
use strict;

#takes a (assumedely saturated color) and returns
#a gray of similar hue...also takes a lightness value
#and a saturation compression value, both
#ranging from 0 to 255;
sub slightGray {
    my $red = shift;
    my $green = shift;
    my $blue = shift;

    #cuz we don't wanna divide by 0. that'd be baaaad.
    $red = ($red == 0)? 1 : $red;
    $green = ($green == 0)? 1 : $green;
    $blue = ($blue == 0)? 1 : $blue;


    my $lightness = shift;
    my $saturation = shift;
    
    my $dominantColor;
    if($red > $blue && $red > $green) {
	$dominantColor = 0;
    } elsif($blue > $green) {
	$dominantColor = 2;
    } else {
	$dominantColor = 1;
    }

    my $red2;
    my $green2;
    my $blue2;

#red
    if($dominantColor == 0) {
	my $gr = $green / $red;
	my $br = $blue / $red;

	my $gm = (((1 - $gr) / 255) * $saturation) + $gr;
	my $bm = (((1 - $br) / 255) * $saturation) + $br;

	$red2 = $lightness;
	$green2 = $red2 * $gm;
	$blue2 = $red2 * $bm;

    }
    #green
    if($dominantColor == 1) {
	my $rg = $red / $green;
	my $bg = $blue / $green;

	my $rm = (((1 - $rg) / 255) * $saturation) + $rg;
	my $bm = (((1 - $bg) / 255) * $saturation) + $bg;

	$green2 = $lightness;
	$red2 = $green2 * $rm;
	$blue2 = $green2 * $bm;
    }
    #blue
    if($dominantColor == 2) {
	my $rb = $red / $blue;
	my $gb = $green / $blue;

	my $rm = (((1 - $rb) / 255) * $saturation) + $rb;
	my $gm = (((1 - $gb) / 255) * $saturation) + $gb;

	$blue2 = $lightness;
	$red2 = $blue2 * $rm;
	$green2 = $blue2 * $gm;
    }

    return (int($red2), int($green2), int($blue2));
    
 }   

#takes a filename. File must be a jpeg.
sub grabColor {
    my $filename = shift;

    my $buckets = 256;
    my $sizePerBucket = 256 / $buckets;
    
    my $img = Imager->new();
    $img->read(file => $filename, type => "jpeg")
	or die "Cannot read image $filename: ", $img->errstr;
    $img = $img->scaleY(pixels => 50);
    $img = $img->scaleX(pixels => 50);

    my $redBest = 0;
    my $greenBest = 0;
    my $blueBest = 0;
    my $satBest = 1;

    for(my $y = 0; $y < 50; $y++) {
	for(my $x = 0; $x < 50; $x++) {
	    my $color = $img->getpixel(x=>$x, y=>$y);
	    my $red;
	    my $green;
	    my $blue;
	    my $alpha;
	    ($red, $green, $blue, $alpha) = $color->rgba();

	    if($red < 11) {$red = 10;}
	    if($green < 10) {$green = 10;}
	    if($blue < 11) {$blue = 10;}

	    if($red < 96 && $green < 96 && $blue < 96) {
		next;
	    }

	    my $redGreen = $red / $green;
	    if($redGreen < 1) {
		$redGreen = 1/$redGreen;
	    }

	    my $redBlue = $red / $blue;
	    if($redBlue < 1) {
		$redBlue = 1/$redBlue;
	    }

	    my $blueGreen = $blue / $green;
	    if($blueGreen < 1) {
		$blueGreen = 1/$blueGreen;
	    }

	    my $max;

	    if($redGreen > $redBlue) {
		$max = $redGreen;
	    } else {
		$max = $redBlue;
	    }

	    if($blueGreen > $max) {
		$max = $blueGreen;
	    }

	    #$max = ($redGreen + $redBlue + $blueGreen) / 3;

	    if($max > $satBest) {
		$satBest = $max;
		$redBest = $red;
		$greenBest = $green;
		$blueBest = $blue;
	    }
	}
    }

	    
    return ($redBest, $greenBest, $blueBest);
}
	    

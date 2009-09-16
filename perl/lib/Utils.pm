package Utils;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(email exiftime);

use strict;

use lib "./";
use Settings;
use Email::Send;
use Template;

#good random seed. from programming perl.
srand ( time() ^ ($$ + ($$ << 15)) ); 

sub email {
    my $to = shift;
    my $from = shift;
    my $subject = shift;
    my $body = shift;

    my $msg = "To: $to\nFrom: $from\nSubject: $subject\n\n$body";

    my $host = Settings::settings("SMTPHost");
    my $success = Email::Send::send SMTP => $msg, $host;
    unless($success) {
	print "failed to send email";
    }
}

sub message {
    my $msg = shift;

    my $template = Settings::settings("templateLib") . "\/message.html";
    my $html = Template::fillTemplate($template, [$msg]);
    return $html;
}

# returns html to do an immediate redirect.
sub redirect {
    my $page = shift;

    my $html = "<html><head><META http-equiv=\"refresh\" content=\"0;URL=$page\"></head></html>";
    return $html;
}

#takes an image filename, and returns a list of
#(width, height).
sub resolution {
    my $image = shift;

    my $id = Settings::settings("identify");

    my $info = `$id $image`;

    my @pieces = split(/ /, $info);
    my $res = $pieces[2];
    my @wh = split(/x/, $res);
    return @wh;
}

# gets timestamp of an image.
# takes image path, ref to list.
# if timestamp exists, list will be filled with
# year, month, day, hour, minute, second, and nonzero
# will be returned. If no timestamp, 0 will be returned.
sub exiftime {
    my $file = shift;    
    my $timeref = shift;

    return 0 if($file eq "");

    my $exifcom = Settings::settings("exiftagsCommand");
    my @output = `$exifcom $file`;
    chomp(@output);

    my $success = 0;
    foreach(@output) {
	#Image Generated: 2003:04:14 01:15:32
	next unless(/Image Generated:/);

	$_ =~ s/\s+/ /g;
	my @broken1 = split(/ /, $_);
	my $date = $broken1[2];
	my $ttime = $broken1[3];

	my @brokendate = split(/:/, $date);
	my @brokentime = split(/:/, $ttime);

	$$timeref[0] = $brokendate[0];
	$$timeref[1] = $brokendate[1];
	$$timeref[2] = $brokendate[2];

	$$timeref[3] = $brokentime[0];
	$$timeref[4] = $brokentime[1];
	$$timeref[5] = $brokentime[2];

	$success = 1;
	last;
    }

    return $success;
}

# WARNING, seems not all cameras have these tags.
# takes image filename and reference to list.
# returns 1 for success, 0 for failure.
# populates list with (width, height) in pixels of image.
sub exifres {
    my $file = shift;    
    my $resref = shift;

    return 0 if($file eq "");

    my $exifcom = Settings::settings("exiftagsCommand");
    my @output = `$exifcom $file`;
    print @output;
    chomp(@output);

    my $width;
    my $height;

    my $success = -1;
    foreach(@output) {
	#Image Width: 3072
	#Image Height: 2048

	if(/Image Width:/) {
	    print "found width\n";
	    $_ =~ s/\s+/ /g;
	    my @broken1 = split(/ /, $_);
	    $width = $broken1[1];
	    $success += 1;
	    next;
	} elsif(/Image Height:/) {
	    $_ =~ s/\s+/ /g;
	    my @broken1 = split(/ /, $_);
	    $height = $broken1[1];
	    $success += 1;
	    next;
	} else {
	    next;
	}
    }

    @$resref = ($width, $height);
    if($success != 1) {
	$success = 0;
    }

    return $success;
}
 
# returns a (probably) unique integer based on the time of the
# call and a large random number.
sub uniqueInt {
    my $a = time();
    $a = ($a % 31536000) . int(rand(1000000000));
    # mod down the time since most significant digits will be relatively stable
    # accross calls (mods so that $a is seconds since beginning of year), then
    # concats a random number.
    return $a;
}

#returns string of time in hh:mm:ss month day year
#takes reference to a list that is (year, month, day, hour, minute, second).
sub timeformat {
    my $ref = shift;
    my @list = @$ref;

    my @months = qw(january february march april may june july august september october november december);
    my @digits = qw(00 01 02 03 04 05 06 07 08 09);

    my $year = $list[0];
    my $month = $months[$list[1] - 1];
    my $day = $list[2];
    my $hour = ($list[3] < 10)? $digits[$list[3]] : $list[3];
    my $min = ($list[4] < 10)? $digits[$list[4]] : $list[4];
    my $sec = ($list[5] < 10)? $digits[$list[5]] : $list[5];

    return "$hour:$min:$sec, $month $day, $year";
}

# takes a filename and string and logs the string to the filename
sub log {
    my $file = shift;
    my $message = shift;

    open(FILE, ">>$file") or return;
    print FILE $message;
    print FILE "\n";
    close(FILE);
}

#returns a string giving current time as hh:mm:dd, month, day, year
sub nicetime {
    my @times = localtime(time());

    my $year = $times[5] + 1900;

    my @months = qw(january february march april may june july august september october november december);
    my @digits = qw(00 01 02 03 04 05 06 07 08 09);

    my $month = $months[$times[4]];
    my $day = $times[3];
    my $hour = ($times[2] < 10)? $digits[$times[2]] : $times[2];
    my $min = ($times[1] < 10)? $digits[$times[1]] : $times[1];

    return "$hour:$min, $month $day, $year";
}

# takes an int ("num") and a list ref, and divides the list into
# num separate lists (alphabetized) each with roughly the same number
# of elements. takes a ref to a list, elements of which will be refs
# to the num number of lists. The input and final output lists, each element
# is a ref to a hash with keys uid and email.
sub alphaSplitList {
    my $n = shift;
    my $inlist = shift; #listref, elements are hash refs.
    my $outlists = shift; #listref...elements will be listrefs too.

    my $perlist = int(scalar(@$inlist) / $n);

    my @sorted = sort {lc($a->{name}) cmp lc($b->{name})} @$inlist;

    my $index = 0;

    # just do the first n - 1 here.
    for(my $i = 0; $i < $n - 1; $i++) {
	my @out;
	for(my $j = 0; $j < $perlist; $j++) {
	    push(@out, $sorted[$index]);
	    $index++;
	}
	push(@$outlists, \@out);
    }
    
    my @out;
    #the last group may have slightly more than $perlist.
    for(my $i = $index; $i < scalar(@sorted); $i++) {
	push(@out, $sorted[$index]);
	$index++;
    }

    push(@$outlists, \@out);
}

#takes time string in sql format ("yyyy-mm-dd hh:mm:ss-tz") and an offset
#and returns a list of hour, minute, second. ignores the embedded sql format
#offset.
sub sqlTime {
    my $tstring = shift;
    my $offset = shift;

    my @b1 = split(/\s/, $tstring);
    my @b2 = split(/\-/, $b1[1]);
    my @b3 = split(/\:/, $b2[0]);

    my $hour = $b3[0];
    my $minute = $b3[1];
    my $second = $b3[2];

    $hour += $offset;

    my @digits = qw(00 01 02 03 04 05 06 07 08 09);

    my $hour2 = ($hour < 10)? $digits[$hour] : $hour;
    my $minute2 = ($minute < 10)? $digits[$minute] : $minute;
    my $second2 = ($second < 10)? $digits[$second] : $second;

    return ($hour2, $minute2, $second2);
}

sub toWebColor {
    my $red = shift;
    my $green = shift;
    my $blue = shift;

    my $webred = sprintf("%02x", $red);
    my $webgreen = sprintf("%02x", $green);
    my $webblue = sprintf("%02x", $blue);

    return $webred . $webgreen . $webblue;

}

sub summary {
    my $text = shift;
    my $size = shift;

    if(length($text) <= $size) {
        return $text;
    }

    my @parts = split(/\s/, $text);
    my $out;
    my $index = 0;
    my $next = $parts[$index];
    while((length($out) + length($next)) <= $size) {
        $out .= " $next";
        $index++;
        $next = $parts[$index];
    }

    $out .= "...";
    return $out;
}


sub escapeCaption {
    my $caption = shift;

    $caption =~ s/\'/\\\'/g;
    $caption =~ s/</\&lt;/g;
    $caption =~ s/>/\&gt;/g;

    return $caption;
}

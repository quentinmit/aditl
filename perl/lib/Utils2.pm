package Utils;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(email, exiftime);

use strict;

use lib "./";
use Settings;
use Email::Send;
use Template;

#good random seed. from programming perl.
srand ( time() ^ ($$ + ($$ << 15)) ); 


sub log {
    my $file = shift;
    my $message = shift;
    open(FILE, ">$file") or die "couldn't open log file $file: $!";
}

sub nicetime {
    my @t = localtime(time());
    



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

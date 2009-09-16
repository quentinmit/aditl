#!/usr/bin/perl -w
use strict;

use lib "./";
use lib "../../perl/lib";

use Database2;
use Utils;

use vars qw($db);

$db = Database2->new();
$db->connect(Settings::settings("dbName"));

#usage resize.pl uid.
#returns 0 on succes..1 on failure

my $uid = $ARGV[0];

my $photodir = Settings::settings("rootPhotoDir") . "/$uid";
unless(-d $photodir) {
    fail($uid, "couldn't find user's photo directory at $photodir");
}

my $med = $photodir . "/med";
my $small = $photodir . "/small";
my $tiny = $photodir . "/tiny";

mydo("mkdir $med");
mydo("mkdir $small");
mydo("mkdir $tiny");

opendir(DIR, "$photodir") or die $!;
my @jpgs = grep { /\.jpg$/i && -f "$photodir/$_" } readdir(DIR);
close(DIR);

#rename things with spaces and quotes.

foreach(@jpgs) {
    if($_ =~ /\s/ ||
       $_ =~ /\'/ ||
       $_ =~ /\"/ ||
       $_ =~ /\)/ ||
       $_ =~ /\(/
       ) {
	my $nn = $_;
	$nn =~ s/\s/_/g;
	$nn =~ s/\'//g;
	$nn =~ s/\"//g;
	$nn =~ s/\)//g;
	$nn =~ s/\(//g;
	system("/bin/mv \"$photodir/$_\" \"$photodir/$nn\"");
    }
}

opendir(DIR, "$photodir") or die $!;
@jpgs = grep { /\.jpg$/i && -f "$photodir/$_" } readdir(DIR);
close(DIR);


my @convert;
my $conv = Settings::settings("convert");

#geometry widthxheight maintains aspect ratio, using 
#dims as the maximum.

foreach(@jpgs) {
    $|=1;
    print ("*");
    mydo("$conv $photodir/$_ -geometry 600x350 $med/$_");
    mydo("$conv $photodir/$_ -geometry x225 $small/$_");
    mydo("$conv $photodir/$_ -geometry 50x50 $tiny/$_");
}

#opendir(DIR, "$med") or die $!;
#my @checkjpgs = grep { /\.jpg$/i && -f "$med/$_" } readdir(DIR);
#close(DIR);


#if(scalar(@jpgs) != scalar(@checkjpgs)) {
#    fail($uid, "resizing of jpegs failed");
#}

$db->setImportStatus($uid, "resize-complete");

exit 0;





sub fail {
    my $uid = shift;
    my $message = shift;

    my $m2 = "[" . Utils::nicetime() . "] [uid: $uid] " . $message;
    Utils::log(Settings::settings("logDirectory") . "/upload-resize.log", $m2);
    exit 1;
}

sub mydo {
    my $command = shift;
    return system($command);
    #print "$command\n";
    #return 0;
}






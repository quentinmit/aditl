#!/usr/bin/perl -w
use strict;

use lib "./";
use lib "../../perl/lib";

use Database2;
use Utils;
use ImportPhoto;

use vars qw($db);

$db = Database2->new();
$db->connect(Settings::settings("dbName"));

#usage import-db.pl uid.
#returns 0 on succes..1 on failure

my $uid = $ARGV[0];
unless($uid) {
    print "no uid\n";
    exit 1;
}

my $photodir = Settings::settings("rootPhotoDir") . "/$uid";
unless(-d $photodir) {
    fail($uid, "couldn't find user's photo directory at $photodir");
}

my $med = $photodir . "/med";
my $small = $photodir . "/small";
my $tiny = $photodir . "/tiny";

my @dirs = ($med, $small, $tiny);
my @tables = ("large_photos", "med_photos", "small_photos");
my @urlBaseFrags = ("med", "small", "tiny");
my $index = 0;

my $noErrors = 1;

my %phids; #photo ids;

my $dir;
foreach $dir (@dirs) {
    opendir(DIR, "$dir") or die $!;
    my @jpgs = grep { /\.jpg$/i && -f "$dir/$_" } readdir(DIR);
    close(DIR);
    foreach(@jpgs) {
	my $phid;
	if(exists($phids{$_})) {
	    $phid = $phids{$_};
	} else {
	    $phid = $db->nextPhid();
	    $phids{$_} = $phid;
	}
	
	my $table = $tables[$index];

	my $url = Settings::settings("photoURLBase") . "/$uid/" . $urlBaseFrags[$index] .
	    "/$_";
	my $status = ImportPhoto::importPhoto($phid, $uid, $db, "$dir/$_", $table, $url);
	unless($status) {
	    fail($uid, "failed to import $dir/$_");
	}
    }
    $index++;
}

$db->setImportStatus($uid, "import-complete");
exit 0;




sub fail {
    my $uid = shift;
    my $message = shift;

    my $m2 = "[" . Utils::nicetime() . "] [uid: $uid] " . $message;
    Utils::log(Settings::settings("logDirectory") . "/upload-dbimport.log", $m2);
    exit 1;
}

sub mydo {
    my $command = shift;
    return system($command);
    #print "$command\n";
    #return 0;
}






#!/usr/bin/perl -w
use strict;

#copies the uploaded raw zip file to a temporary directory.
#unzips the file.
#checks that the directory structure is flat.

#usage unzip.pl uid
#exits with 0 on success, 1 on failure.

use lib "./";
use lib "../../perl/lib";

use Database2;
use Utils;

use vars qw($db);

$db = Database2->new();
$db->connect(Settings::settings("dbName"));


my $uid = $ARGV[0];
my $zipfile = $db->getZipFilePath($uid);
my $logfile = Settings::settings("logDirectory") . "/import-unzip.log";

unless(-f $zipfile) {
    fail($uid, "failed to find raw zip file at $zipfile");
}

#create the user's root photo directory and move the zip file to it
my $photoDir = Settings::settings("rootPhotoDir") . "/$uid";
mydo("mkdir $photoDir");
mydo("cp $zipfile $photoDir/$uid.zip");

$zipfile = "$photoDir/$uid.zip";



#unzip the zip file
my $zipcommand = Settings::settings("unzip");

my $status = mydo("$zipcommand -d $photoDir $zipfile");
if($status != 0) {
    fail($uid, "unzip failed unzipping $zipfile");
}


my @files = `find $photoDir -type f`;
chomp(@files);
foreach(@files) {
    if(/\//) {
	my $newname = $_;
	$newname =~ s/$photoDir\///g;
	$newname =~ s/\//_/g;

	next if($_ eq "$photoDir\/$newname");

	mydo("mv $_ $photoDir\/$newname");
    }
}

#success
unlink($zipfile);
$db->setImportStatus($uid, "unzip-complete");
exit 0;


sub fail {
    my $uid = shift;
    my $message = shift;

    my $m2 = "[" . Utils::nicetime() . "] [uid: $uid] " . $message;
    Utils::log(Settings::settings("logDirectory") . "/upload-unzip.log", $m2);

    $db->setImportStatus($uid, "unzip-failed");
    exit 1;
}

sub mydo {
    my $command = shift;
    return system($command);
}






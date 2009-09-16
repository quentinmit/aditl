#!/usr/bin/perl
use strict;

use lib "../perl/lib";
use Timeline;
use Database;
use Utils;

use vars qw($db);

$db = Database->new();
$db->connect(Settings::settings("dbName"));


my @uids;
$db->usersWithPhotos(\@uids);
my $eventDate = Settings::settings("eventDate");

foreach(@uids) {
    my @phids = $db->getPhotosBetween($_, $eventDate . " 00:00:00", $eventDate . " 23:59:59");

    my @photos;
    foreach(@phids) {
	my %info;
	$db->photoInfo($_, 'small_photos', \%info);

	$info{filename} = $info{file};
	my @time = Utils::sqlTime($info{time});
	$info{time} = $time[0] * 60 + $time[1];
	
	push(@photos, \%info);
    }

    my %options;
    Timeline::defaultOptions(\%options);

    $options{timelineWidth} = 600;
    $options{timelineHeight} = 24;
    my $path = Settings::settings("tinyBarcodePath");
    $options{outputFile} = "$path/$_.jpg";
    $options{imageData} = \@photos;
    $options{eventWidth} = 5;
    Timeline::makeSmallTimeline(\%options);
}


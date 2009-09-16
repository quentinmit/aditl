#!/usr/bin/perl
use strict;

#changes times for a user
#usage: change-time uid offset 
#offset is in hours and can be positive or negative 

use lib "/usr/local/aditl2/perl/lib";
use Database;
use Utils;

use vars qw($db);

$db = Database->new();
$db->connect("aditl2");

my @photos;
my $conn = $db->{connection};
my $uid = $ARGV[0];
my $offset = $ARGV[1];

my $query = "select phid, time from large_photos where uid = $uid;";
my $res = $conn->exec($query);
my @row;
while(@row = $res->fetchrow()) {
    my %hash;
    $hash{phid} = $row[0];
    $hash{date} = $row[1];
    push(@photos, \%hash);
}

update(\@photos, "large_photos", $offset);
update(\@photos, "med_photos", $offset);
update(\@photos, "small_photos", $offset);

sub update {
    my $photos = shift;
    my $table = shift;
    my $offset = shift;

    foreach(@$photos) {
	my @time = sqlTime($_->{date}, 0);
	$time[3] += $offset;

	if($time[3] > 23) {
	    $time[3] -= 24;
	    $time[2] += 1;
	}

	if($time[3] < 0) {
	    $time[3] += 24;
	    $time[2] -= 1;
	}

	my $ts = "$time[0]-$time[1]-$time[2] $time[3]:$time[4]:$time[5]";
	my $conn = $db->{connection};
	my $phid = $_->{phid};
	my $query = "update $table set time = '$ts' where phid = $phid;";
	$conn->exec($query);
	print "$query\n";
    }
}
    
#returns year, month, day, hour, minute, second
sub sqlTime {
    my $tstring = shift;

    my @b1 = split(/\s/, $tstring);
    my @b2 = split(/\-/, $b1[1]);
    my @b3 = split(/\:/, $b2[0]);
    my @b4 = split(/-/, $b1[0]);

    my $year = $b4[0];
    my $month = $b4[1];
    my $day = $b4[2];
    my $hour = $b3[0];
    my $minute = $b3[1];
    my $second = $b3[2];

    return ($year, $month, $day, $hour, $minute, $second);
}

#!/usr/bin/perl
use strict;

#converts photos for person with given uid to same time but 2005-4-21.

use lib "/usr/local/aditl2/perl/lib";
use Database;
use Utils;

use vars qw($db);

$db = Database->new();
$db->connect("aditl2");

my @photos;
my $conn = $db->{connection};
my $uid = $ARGV[0];

my $query = "select phid, time from large_photos where uid = $uid;";
my $res = $conn->exec($query);
my @row;
while(@row = $res->fetchrow()) {
    my %hash;
    $hash{phid} = $row[0];
    $hash{date} = $row[1];
    push(@photos, \%hash);
}

update(\@photos, "large_photos");
update(\@photos, "med_photos");
update(\@photos, "small_photos");

sub update {
    my $photos = shift;
    my $table = shift;

    foreach(@$photos) {
	my @time = Utils::sqlTime($_->{date}, 0);
	my $ts = "2005-4-21 $time[0]:$time[1]:$time[2]";
	my $conn = $db->{connection};
	my $phid = $_->{phid};
	my $query = "update $table set time = '$ts' where phid = $phid;";
	$conn->exec($query);
	print "$query\n";
    }
}
    

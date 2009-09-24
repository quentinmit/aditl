#!/usr/bin/perl
use strict;

use lib "../perl/lib";
use Database;
use Utils;

use vars qw($db);

$db = Database->new();
$db->connect(Settings::settings("dbName"));

my @phids;
my $conn = $db->{connection};

my $query = "select phid, uid from photos where medium_size IS NULL";
my $sth = $conn->prepare($query);
$sth->execute;
while (my $row = $sth->fetchrow_hashref()) {
  my ($width, $height) = Utils::imagesize(Utils::imagePath($row, "medium"));
  $conn->do("UPDATE photos SET medium_size = ? WHERE phid = ?", undef, "$width,$height", $row->{phid});
}

#!/usr/bin/perl
use strict;

use lib "../perl/lib";
use Database;
use Utils;
use Upload;

use vars qw($db);
use Image::ExifTool qw(:Public);
use File::Spec::Functions;

$db = Database->new();
$db->connect(Settings::settings("dbName"));

my @phids;
my $conn = $db->{connection};
my $conv = Settings::settings("convert");

my $query = "select phid, uid, original_path from photos";
my $sth = $conn->prepare($query);
$sth->execute;
while (my $row = $sth->fetchrow_hashref()) {
  my $info = ImageInfo($row->{original_path}, [qw(Orientation)]);

  my $orientation = $info->{Orientation};

  if ($orientation && $orientation !~ m|normal|) {
    print "$row->{phid} has orientation: $orientation\n";

    my $userroot = catdir(Settings::settings("rootPhotoDir"), $row->{uid});

    foreach my $size (keys %Upload::SIZES) {
      print "Regenerating $size\n";
      my $sizedir = catdir($userroot, $size);
      -d $sizedir || mkdir($sizedir) or die "Couldn't mkdir: $!";

      system($conv, $row->{original_path}, "-auto-orient", "-geometry", $Upload::SIZES{$size}, catfile($sizedir, "$row->{phid}.jpg"));

    }
    my ($width, $height) = Utils::imagesize(Utils::imagePath($row, "medium"));
    print "New medium size: ${width}x${height}\n";
    $conn->do("UPDATE photos SET medium_size = ? WHERE phid = ?", undef, "$width,$height", $row->{phid});
  }
}

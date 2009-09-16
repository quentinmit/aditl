package ImportPhoto;

require Exporter;
@ISA = qw(Exporter);

use strict;

use lib "/usr/local/aditl2/perl/lib";
use Settings;
use Utils;


# takes uid, db ref and imports that photo's info
# into the db. 
sub importPhoto {
    my $phid = shift;
    my $uid = shift;
    my $db = shift;
    my $file = shift;
    my $table = shift;
    my $url = shift;

    my ($width, $height) = Utils::resolution($file);

    my @date;
    my $status = Utils::exiftime($file, \@date);

    unless($status) {
	return 0;
    }

    my $datestamp = join("-", ($date[0], $date[1], $date[2])) . " " .
    join(":", ($date[3], $date[4], $date[5]));

    $db->insertPhoto($table, $phid, $uid, $width, $height, $url, $file, $datestamp);

    return 1;
}

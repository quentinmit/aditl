use strict;
use lib "./";
use Database;

use Utils;

my $db = Database->new();
$db->connect("aditl2");

print join "\n", $db->getPhotosBetween("35", "2005-4-21 8:00:00", "2005-4-21 13:00:00");

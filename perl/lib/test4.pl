use strict;
use lib "./";
use Database;

use Utils;

my $db = Database->new();
$db->connect("aditl2");

$db->photoVote(1, 2, 3);

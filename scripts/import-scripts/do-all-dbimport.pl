#!/usr/bin/perl -w
use strict;

# does db import for all people with 'do-db-import-manual'.

use lib "/usr/local/aditl2/scripts/import-scripts";

use Database2;

use vars qw($db);

$db = Database2->new();
$db->connect("aditl2");

my $myimport = "/usr/local/aditl2/scripts/import-scripts/import-db.pl";

my @uids = $db->importStatusWhere("do-db-import-manual");

foreach(@uids) {
    if(system("$myimport $_")) {
	next;
    }
}


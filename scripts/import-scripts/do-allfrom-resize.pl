#!/usr/bin/perl -w
use strict;

# does resize and db import for all people with 'do-resize-manual'.

use lib "/usr/local/aditl2/scripts/import-scripts";

use Database2;

use vars qw($db);

$db = Database2->new();
$db->connect("aditl2");

my $myimport = "/usr/local/aditl2/scripts/import-scripts/import-db.pl";
my $resize = "/usr/local/aditl2/scripts/import-scripts/resize.pl";

my @uids = $db->importStatusWhere("do-resize-manual");

foreach(@uids) {
    if(system("$resize $_")) {
	next;
    }
	
    if(system("$myimport $_")) {
	next;
    }
}


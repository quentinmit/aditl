#!/usr/bin/perl -w
use strict;

use lib "./";
use lib "../../perl/lib/";

use Database2;
use Settings;

use vars qw($db);

$db = Database2->new();
$db->connect(Settings::settings("dbName"));

my $unzip = Settings::settings("pathBase") . "/scripts/import-scripts/unzip.pl";
my $resize = Settings::settings("pathBase") . "/scripts/import-scripts/resize.pl";
my $myimport = Settings::settings("pathBase") . "/scripts/import-scripts/import-db.pl";

my @uids = $db->getNewUploads();

foreach(@uids) {
    if(system("$unzip $_")) {
	next;
    }

    if(system("$resize $_")) {
	next;
    }

    if(system("$myimport $_")) {
	next;
    }
}


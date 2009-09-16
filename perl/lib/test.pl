use strict;
use lib "./";
use Database;

use Utils;

#print Utils::nicetime();

my $db = Database->new();
$db->connect("aditl2");

my @list;
$db->getAllEmails(\@list);

#foreach(@list) {
#    print $_->{uid} . " " . $_->{email} . "\n";
#}

my @sorted;
Utils::alphaSplitList(5, \@list, \@sorted);

foreach(@sorted) {
    my @thislist = @$_;
    print "begin list ====================\n";
    foreach(@thislist) {
	print $_->{email} . " " . $_->{uid} . "\n";
    }
    print "\n\n\n";
}

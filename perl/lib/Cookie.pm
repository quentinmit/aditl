package Cookie;

#generates authentication tokens, stored as cookies in user's browser
#and in the db, so they only have to sign in once.

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw();

use strict;
#use lib "/usr/local/aditl2/perl/lib";
use Database;

use CGI qw(:standard);

#good random seed. from programming perl.
srand ( time() ^ ($$ + ($$ << 15)) );

sub createAuthToken {
    #don't want a token of 0.
    return int(rand(9999999999)) + 1;
}

#takes a cgi object and db object and returns uid of user if user is logged in
#ow returns 0.
sub isUserLoggedIn {
    my $cgi = shift;
    my $db = shift;

    my $authid = $cgi->param("aditlauthid") || $cgi->url_param("aditlauthid") || $cgi->cookie("aditlauthid");
    my $authtoken = $cgi->param("aditlauthtoken") || $cgi->url_param("aditlauthtoken") || $cgi->cookie("aditlauthtoken");

    unless(defined($authid) && defined($authtoken)) {
	return 0;
    }

    my @info;
    my $found = $db->getAuthToken($authid, \@info);
    unless($found) {
	return 0;
    }

    my $token = $info[0];
    my $uid = $info[1];

    if($token eq $authtoken) {
	return $uid;
    } else {
	return 0;
    }
}


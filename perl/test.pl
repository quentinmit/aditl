use strict;

my $test = $ARGV[0];

if($test =~ /[^\w-]/) {
    print "bad\n";
} else {
    print "ok\n";
}

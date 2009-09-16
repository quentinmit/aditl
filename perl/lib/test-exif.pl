use strict;
use lib "./";
use Database;
use Utils;

$|=1;

my $file = $ARGV[0];

print "using file $file\n";

my @ttime;
my @res;
my $success = Utils::exiftime($file, \@ttime);
my $success2 = Utils::exifres($file, \@res);
print "success2 is $success2\n";
if($success) {
    print join(" ", @ttime ) . "\n";
    print join(" x ", @res) . "\n";
} else {
    print "no time exiftag\n";
}


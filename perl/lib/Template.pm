package Template;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(fillTemplate);

use strict;

# Opens an html template and fills in the appropriate photos and text
# The format of the template is a newline separated list of keywords to
# be replaced (order of keywords matching order of replacing text) ending
# with <template> followed by the template body.
# empty lines in keyword list are ignored.
sub fillTemplate {
    my $templateFile = shift; #file name
    my $objectRef = shift;
    my @objects = @$objectRef;
    # list of text bits to be swapped in for the keywords found in the
    # template.

# The proc just takes objects in order and replaces the variables found
# in the html template in order.

    open(FILE, "$templateFile") or die "Couldn't open template file: $!\n";
    my @temp = <FILE>;
    my $template = join("", @temp);
    close(FILE);
    
    @temp = split(/\<template\>/, $template);

    my $templateBody = $temp[1];
    my @variables1 = split(/\n/, $temp[0]);
    my @variables; #keywords we'll be substituting for in template body

    foreach(@variables1) {
	unless($_ =~ /^\n$$/) {
	    push(@variables, $_);
	}
    }

    if(scalar(@objects) != scalar(@variables)) {
	die "in 'fillTemplate' number of template keywords and replacement text does not match\n";
    }

    for(my $i = 0; $i < scalar(@variables); $i++) {
	$templateBody =~ s/$variables[$i]/$objects[$i]/g;
    }

    return $templateBody;
}

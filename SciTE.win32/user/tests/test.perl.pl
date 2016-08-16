#
# Perl functions don't have parameters, their arguments are passed
# in an array @_.  You can simulate parameters by assigning to a
# list, but you can just apply the usual array operations to @_.
#

use strict;

sub parg {
    my($a, $b, $c) = @_;

    print "A: $a $b $c\n";
    print "B: $#_ [@_]\n\n";
}

parg("Hi", "there", "fred");

my @a1 = ("Today", "is", "the", "day");
parg(@a1);

parg("Me", @a1, "too");

my $joe = "sticks";
&parg ("Pooh $joe");

parg;

my @a2 = ("Never", "Mind");
parg @a2, "Boris", @a1, $joe;

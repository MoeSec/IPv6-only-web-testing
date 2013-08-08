#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(time);



my $inFile = $ARGV[0] or die "Enter file name";

open (MYFILE, $inFile) or die "Cant open file";

my @domains = <MYFILE>;

foreach (@domains) {
    chomp;
    `unlink temp`;
    my $before = time();
    `wget -4 -p -o /dev/null -O temp -T 10 $_ 2>/dev/null`;
    my $after = time();
    open (RESULT, '>>result.txt') or die "cant open file";
    print RESULT "$_ \t";
    printf RESULT ("%.2f\n", $after - $before);
}
close (MYFILE);

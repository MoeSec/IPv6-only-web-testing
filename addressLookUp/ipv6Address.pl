#!/usr/bin/perl

use strict;
use warnings;

my $inFile = $ARGV[0] or die "Enter file name";

open (MYFILE, $inFile) or die "Cant open file";

my @domains = <MYFILE>;

foreach (@domains) {
    chomp;
    my $command = "nslookup -type=AAAA $_";
    my $result = `$command`;
    
    my $newstring = substr($result, rindex($result, 'AAAA') + 13);
    
    open (RESULT, '>>result.txt') or die "cant open file";
    
    if (index($newstring, 'Non-authoritative') != -1){
        print RESULT "$_ \t IPv4 - only \n";
    }
    else
    {
        my $string = substr($newstring, 0, index($newstring, 'Au') - 2);
        print RESULT "$_ \t $string \n";
    }
}
close (MYFILE);
close (RESULT);

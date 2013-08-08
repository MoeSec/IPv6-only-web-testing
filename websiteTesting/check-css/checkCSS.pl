#!/usr/bin/perl
use strict;
use warnings;

use HTML::TokeParser::Simple;

my $dnFile = $ARGV[0] or die "Enter domains file.\n";
open (URLS, $dnFile) or die "Cant open file.\n";
my @domains = <URLS>;

foreach (@domains) {
    chomp;
    my $website = "$_";
    `wget -6 -T 3 -t 3 -k -O temp.html -P /dev/null -o /dev/null $website 2>/dev/null`;

    my $url = 'temp.html';
    
    # Getting stylesheet reference links
    if (-z "$url"){
        open (RESULT, '>>result.txt') or die "Cant open results file\n";
        print RESULT "$website \t";
        print RESULT "Not loading  \n";
        close(RESULT);
    }
    else{
        my $parser = HTML::TokeParser::Simple->new($url);
        while( my $link = $parser->get_tag('link') ){
            my $rel = $link->get_attr('rel');
            if (defined $rel){
                my $href = $link->get_attr('href');
                if(defined $href){
                    `wget -6 -T 3 -t 3 -O /dev/null -o log.txt --no-check-certificate $href 2>/dev/null`;
            
                    my $logFile = "log.txt";
                    open(LOGFILE, $logFile) or die "Log file was not created\n";
                    my @lines = <LOGFILE>;
            
                    foreach (@lines){
                        chomp;
                        if (substr("$_", 0, "5") eq "wget:"
                            or substr("$_", -19) eq "Connection refused."
                            or "$_" eq "Giving up."
                            or "$_" eq "20 redirections exceeded."){
                                open (RESULT, '>>result.txt') or die "Cant open results file\n";
                                print RESULT "$website \t";
                                print RESULT "Sorta  \t";
                                print RESULT "$rel link doesn't load \t";
                                print RESULT "$href \n";
                                close(RESULT);
                            }
                    }
                    close(LOGFILE);
                }
            }
        }
    }
}
close(URLS);



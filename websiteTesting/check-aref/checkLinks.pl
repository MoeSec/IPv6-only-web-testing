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
    `wget -6 -k -T 3 -t 3 -O temp.html -P /dev/null -o /dev/null $website 2>/dev/null`;
    
    #getting rid of www. in order to test for link references within the domain.
    my @splitDN = split(/\./, $website);
    if($splitDN[0] eq "www"){
        $website = substr($website, 4, length($website));
    }
    
    my $url = 'temp.html';
    
    # Getting stylesheet reference links
    if (-z "$url"){
        open (RESULT, '>>result.txt') or die "Cant open results file\n";
        print RESULT "$website\t";
        print RESULT "Not loading\n";
        close(RESULT);
    }
    else{
        my $parser = HTML::TokeParser::Simple->new($url);
        my $count = 0;
       
        
        while( my $a = $parser->get_tag('a') ){
            my $href = $a->get_attr('href');
         
            #testing if link is within the domain
            if (defined $href
                and $href =~ /\Q$website\E/
                and $count < 15){
            
                `wget -6 -T 4 -t 4 -O /dev/null -o log.txt --no-check-certificate $href 2>/dev/null`;
            
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
                        print RESULT "$website\t";
                        print RESULT "Sorta\t";
                        print RESULT "Subnetting link doesn't load \t";
                        print RESULT "$href\n";
                        close(RESULT);
                        $count += 1;
                    }
                }
                close(LOGFILE);
            }
        }
    }
}
close(URLS);



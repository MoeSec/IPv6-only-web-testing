#!/usr/bin/perl
use strict;
use warnings;

#Reading URLs from file
my $dnFile = $ARGV[0] or die "Enter domains file.\n";
open (MYFILE, $dnFile) or die "Cant open file.\n";
my @domains = <MYFILE>;


#Testing each website
foreach (@domains) {
    #Generating Log file when performing wget on website
    chomp;
    my $website = "$_" or die "Website not recognize\n";
    `wget -6 -T 3 -t 3 -O /dev/null -o log.txt $website 2>/dev/null`;
    my $logFile = "log.txt";
    open(LOGFILE, $logFile) or die "Log file was not created\n";
    my @lines = <LOGFILE>;

    foreach (@lines){
        chomp;
        #Websites that must be manually checked
        if ("$_" eq "Unable to establish SSL connection."
            or substr("$_", 0, 16) eq "Resource Locator"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "test \t";
            print RESULT "Manual testing.\n";
            last;
        }
        #Successful website load
        elsif ("$_" eq "HTTP request sent, awaiting response... 200 OK"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "Yes \t";
            print RESULT "Further Testing.\n";
            last;
        }
        #Login information required
        elsif("$_" eq "Authorization failed."){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "N/A \t";
            print RESULT "Authorization required.\n";
            last;
        }
        #Internal server error - ERROR 500
        elsif(substr("$_,", 0, 43) eq "HTTP request sent, awaiting response... 500"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "Internal Server Error.\n";
            last;
        }
        #Forbidden site - ERROR 403
        elsif(substr("$_,", 0, 43) eq "HTTP request sent, awaiting response... 403"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "Forbidden Error.\n";
            last;
        }
        #Website not found - ERROR 404
        elsif(substr("$_,", 0, 43) eq "HTTP request sent, awaiting response... 404"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "Website Not Found Error.\n";
            last;
        }
        #Service unavailable - ERROR 503
        elsif(substr("$_,", 0, 43) eq "HTTP request sent, awaiting response... 503"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "Service Unavailable Error.\n";
            last;
        }
        #Connection time out or refused
        elsif(substr("$_", -19) eq "Connection refused."
              or "$_" eq "Giving up."
              or "$_" eq "20 redirections exceeded."){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "Connection Refused or Timeout.\n";
            last;
        }
        #Not IPv6 compatible
        elsif ( substr("$_", 0, 5) eq "wget:"){
            open (RESULT, '>>result.txt') or die "Cant open results file\n";
            print RESULT "$website \t";
            print RESULT "No \t";
            print RESULT "No IPv6 server.\n";
            last;
        }
        close(RESULT);
    }
}
close(LOGFILE);

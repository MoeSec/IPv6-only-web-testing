#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use HTML::TokeParser::Simple;

my $dnFile = $ARGV[0] or die "Enter domains file.\n";
open (URLS, $dnFile) or die "Cant open file.\n";
my @domains = <URLS>;
close(URLS);
my @v6domains=();
my $outputfile="result.csv";
open(OUTPUT, '>',$outputfile);
print OUTPUT "site,error,csslinks,badcss,imges,badimgs,linkds,badlinks\n";

foreach (@domains) {
    chomp;
    my $website = "$_";
    $website =~ s/\s*$//;
    my $v6IP = `dig aaaa +short $website`;
    if (!$v6IP) {
       print OUTPUT "$website,no aaaa record.\n";
       print "$website no aaaa record.\n";
       next;
    }
    my $htmllogfile = $website.".log";
    my $webfile = $website.".html";
    `wget -6 -k -T 3 -t 3 --user-agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3" -O "$webfile" -P /dev/null -o "$htmllogfile" "$website" 2>/dev/null`;
    my @ST = stat($webfile);
    my $htmlfilelength = $ST[7];

    open my $fh, '<', $htmllogfile or die "Log file was not created\n";
    my $wgetlog = do { local $/; <$fh> };
    close $fh;
    unlink($htmllogfile);

    #ssl failures
    if ("$wgetlog" =~ /.*Unable to establish SSL connection\..*/si ||
        "$wgetlog" =~ /Resource Locator/si) {
            print OUTPUT "$website,SSL fault.\n";
            print  "$website SSL fault.\n";
            unlink($htmllogfile);
            unlink($webfile);
    #Successful website load
    } elsif ("$wgetlog" =~ /.*HTTP request sent, awaiting response\.\.\.\s+200\s+OK/si) {
            print "$website reachable via IPv6, running additional tests.\n";
            unlink($htmllogfile);
            runchecks($website);
    #Login information required
    } elsif("$wgetlog" =~ /Authorization failed\./si) {
            print OUTPUT "$website,Authorization required.\n";
            print  "$website, Authorization required.\n";
            unlink($htmllogfile);
            unlink($webfile);
    #Internal server error - ERROR 500
    } elsif("$wgetlog" =~ /HTTP request sent, awaiting response\.\.\.\s+500.*/si) {
            print OUTPUT "$website,Internal Server Error.\n";
            print "$website, Internal Server Error.\n";
            unlink($htmllogfile);
            unlink($webfile);
    #Forbidden site - ERROR 403
    } elsif("$wgetlog" =~ /HTTP request sent, awaiting response\.\.\.\s+403.*/si) {
            print OUTPUT "$website,Forbidden Error.\n";
            print "$website, Forbidden Error.\n";
            unlink($htmllogfile);
            unlink($webfile);
    #Website not found - ERROR 404
    } elsif("$wgetlog" =~ /HTTP request sent, awaiting response\.\.\.\s+404.*/si) {
            print OUTPUT "$website,Website Not Found Error.\n";
            print "$website, Website Not Found Error.\n";
            unlink($webfile);
            unlink($htmllogfile);
    #Service unavailable - ERROR 503
    } elsif("$wgetlog" =~ /HTTP request sent, awaiting response\.\.\.\s+503.*/si) {
            print OUTPUT "$website,Service Unavailable Error.\n";
            print "$website, Service Unavailable Error.\n";
            unlink($webfile);
            unlink($htmllogfile);
    #Connection time out or refused
    } elsif("$wgetlog" =~ /.*Connection refused.*/si ||
            "$wgetlog" =~ /.*Giving up\..*/si ||
            "$wgetlog" =~ /.*20 redirections exceeded\..*/ ) {
            print OUTPUT "$website,Connection Refused or Timeout.\n";
            print "$website, Connection Refused or Timeout.\n";
            unlink($htmllogfile);
            unlink($webfile);
    #Not IPv6 compatible
    } elsif("$wgetlog" =~ /wget:.*/si){
            print OUTPUT "$website,No IPv6 server.\n";
            print  "$website, No IPv6 server.\n";
            unlink($webfile);
            unlink($htmllogfile);
    } elsif ("$htmlfilelength" == 0) {
            print OUTPUT "$website,Zero length HTML returned.\n";
            print  "$website Zero length htmlfile.\n";
            unlink($webfile);
            unlink($htmllogfile);
    } else {
            print OUTPUT "$website,Unknown Issue - no status determined check $webfile and $htmllogfile\n";
    }
}
close(OUTPUT);

sub runchecks {
        my $website="$_[0]";
        my $webfile="$website.html";
        my $parser = HTML::TokeParser::Simple->new($webfile);
        #########################################################################
        ### check images
        #########################################################################
        my $imgcnt=1;
        my $badimgcnt=0;
        print"Checking $website images";
        while( my $img = $parser->get_tag('img') ){
            my $url = $img->get_attr('src');
            if (defined $url && $url !~ /^data:.*/i){

                my $logFile = "$website.imglog.txt";
                print ".";

                `wget --user-agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3" -6 -T 3 -t 3 -O /dev/null -o $logFile --no-check-certificate "$url" 2>/dev/null`;

                open(LOGFILE, '<', "$logFile") or die "Log file was not created\n";
                my @lines = <LOGFILE>;
                close(LOGFILE);
                unlink($logFile);

                foreach (@lines){
                    chomp;
                    if (substr("$_", 0, "5") eq "wget:"
                        or substr("$_", -19) eq "Connection refused."
                        or "$_" eq "Giving up."
                        or "$_" eq "20 redirections exceeded."){
                        $badimgcnt++;
                    }
                }
                $imgcnt++;
            }
        }

        #########################################################################
        ### check css
        #########################################################################
        $parser = HTML::TokeParser::Simple->new($webfile);
        my $csscnt=1;
        my $badcsscnt=0;
        print "\nChecking $website CSS";
        while( my $css = $parser->get_tag('link') ){
            my $rel = $css->get_attr('rel');
            if ($rel && $rel =~ /stylesheet/i ) {
                my $href = $css->get_attr('href');
                if(defined $href){
                     my $logFile = "$website.csslog.txt";
                     print ".";
                    `wget --user-agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3" -6 -T 3 -t 3 -O /dev/null -o $logFile --no-check-certificate "$href" 2>/dev/null`;

                    open(LOGFILE, $logFile) or die "Log file was not created\n";
                    my @lines = <LOGFILE>;
                    close LOGFILE;
                    unlink($logFile);

                    foreach (@lines){
                        chomp;
                        if (substr("$_", 0, "5") eq "wget:"
                            or substr("$_", -19) eq "Connection refused."
                            or "$_" eq "Giving up."
                            or "$_" eq "20 redirections exceeded."){
                                $badcsscnt++;
                            }
                    }
                    $csscnt++;
                }
            }
        }

        #########################################################################
        ### check local links
        #########################################################################
        $parser = HTML::TokeParser::Simple->new($webfile);
        my $domain = $website;
        $domain =~ s/.*?([^.]+\.[^.]+)$/$1/;
        my $acnt = 1;
        my $abadcnt = 0;
        print "\nChecking $website local links";
        while( my $a = $parser->get_tag('a') ){
            my $href = $a->get_attr('href');


            #testing if link is within the domain
            if (defined $href) {
                if ( $href =~ /http(s|):\/\/.*$domain.*/
                   and $acnt < 15){

                   my $logFile = "$website.alog.txt";
                   print ".";
                   `wget --user-agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3" -6 -T 4 -t 4 -O /dev/null -o $logFile --no-check-certificate "$href" 2>/dev/null`;

                   open(LOGFILE, $logFile) or die "Log file was not created\n";
                   my @lines = <LOGFILE>;
                   close(LOGFILE);
                   unlink($logFile);

                   foreach (@lines){
                       chomp;
                       if (substr("$_", 0, "5") eq "wget:"
                           or substr("$_", -19) eq "Connection refused."
                           or "$_" eq "Giving up."
                           or "$_" eq "20 redirections exceeded."){
                           $abadcnt++;
                       }
                   }
                   ###print "$website has good v6 link: $href count: $acnt bads: $abadcnt\n";
                   $acnt++;
                }
            }
        }

        unlink($webfile);
        print OUTPUT "$website,,$csscnt,$badcsscnt,$imgcnt,$badimgcnt,$acnt,$abadcnt\n";
        print "\n$website: CSS:$csscnt CSS failed:$badcsscnt IMG:$imgcnt IMG failed:$badimgcnt Links:$acnt Links failed:$abadcnt\n";
}

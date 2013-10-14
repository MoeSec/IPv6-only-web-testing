** The following script was created to assist with IPv6 only website testing. **

Many websites are enabled for IPv6, but because they also support IPv4, this masks potential problems where only part of the site is actually reachable via IPv6. It is common to see things like CSS, Images, and secondary links that are on another server and that server is not yet IPv6-capable. When one attempts to load sites over IPv6-only, these problems become evident.

This script is based on a set of scripts written by Mauricio Tellez during his summer internship with Time Warner Cable, and subsequently modified by Kamil Ince. It takes a file with a list of domains as an argument, and attempts to access these sites via IPv6 with no fallback to IPv4.
It first tests to see if the site is reachable via IPv6 at all. If it times out, a result is printed in result.csv and it moves on to the next site. If the site is reachable, it does 3 further tests by parsing the HTML it downloads to find CSS references, img tags, and a href tags, and then attempts to access these. For the Href tags, it is filtering so that it is only testing local links, so it'll only test links with the same domain name as the domain under test. Once those tests complete, it will print out the result for that site with the number of elements it found, and how many failed.

Since it tests for IPv6, it should be obvious that the machine running this script must have IPv6 connectivity to get useful results.


All scripts run in a Perl environment using the standard packages except for one package that must be installed individually.

**** MUST INSTALL HTML::TokeParser::Simple PACKAGE IN ORDER TO USE THE HTML TOKENIZER.

Also, this writes out temporary [site].html files and [site].log files while in operation, these all will be deleted as long as the script runs to completion.

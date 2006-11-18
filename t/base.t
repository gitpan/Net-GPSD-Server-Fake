#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 0.1 2006/02/21 eserte Exp $
# Author: Michael R. Davis
#

use strict;
use lib q{lib};
use lib q{../lib};

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 4 }

# just check that all modules can be compiled
ok(eval {require Net::GPSD::Server::Fake; 1}, 1, $@);

my $server = Net::GPSD::Server::Fake->new();
ok(ref $server, "Net::GPSD::Server::Fake");
ok($server->port, "2947");
ok($server->name, "GPSD");

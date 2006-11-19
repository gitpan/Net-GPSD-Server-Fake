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

BEGIN { plan tests => 29 }

# just check that all modules can be compiled
ok(eval {require Net::GPSD::Server::Fake; 1}, 1, $@);

my $server = Net::GPSD::Server::Fake->new();

ok(ref $server, "Net::GPSD::Server::Fake");
ok($server->port, "2947");
ok($server->name, "GPSD");

ok(eval {require Net::GPSD::Server::Fake::Track; 1}, 1, $@);
my $track = Net::GPSD::Server::Fake::Track->new(lat=>39,lon=>-77,speed=>25,heading=>45);
ok(ref $track, "Net::GPSD::Server::Fake::Track");
my $p1=$track->get();
ok(ref $p1, "Net::GPSD::Point");
ok($p1->lat, 39);
ok($p1->lon, -77);
ok($p1->speed, 25);
ok($p1->heading, 45);

my @s1=$track->getsatellitelist();
my $s1=$s1[0];
ok(ref $s1, "Net::GPSD::Satellite");
ok($s1->prn, 0);
ok($s1->elev, 1);
ok($s1->azim, 2);
ok($s1->snr, 3);
ok($s1->used, 4);

ok(eval {require Net::GPSD::Server::Fake::Stationary; 1}, 1, $@);
my $stationary = Net::GPSD::Server::Fake::Stationary->new(lat=>38,lon=>-78);
ok(ref $stationary, "Net::GPSD::Server::Fake::Stationary");
my $p2=$stationary->get();
ok(ref $p2, "Net::GPSD::Point");
ok($p2->lat, 38);
ok($p2->lon, -78);
ok($p2->speed, 0);

my @s2=$stationary->getsatellitelist();
my $s2=$s2[0];
ok(ref $s2, "Net::GPSD::Satellite");
ok($s2->prn, 0);
ok($s2->elev, 1);
ok($s2->azim, 2);
ok($s2->snr, 3);
ok($s2->used, 4);

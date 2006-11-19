#Copyright (c) 2006 Michael R. Davis (mrdvt92)
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package Net::GPSD::Server::Fake::Track;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q{Revision: 0.03} =~ /(\d+)\.(\d+)/);

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->lat($param{'lat'}           ||  39.5);
  $self->lon($param{'lon'}           || -77.5);
  $self->speed($param{'speed'}       ||  20);
  $self->heading($param{'heading'}   ||  0);
}

sub get {
  my $self=shift();
  my $time=shift();
  my $pt0=shift();

  use Geo::Forward;
  use Net::GPSD::Point;
  my $object = Geo::Forward->new();
  my $lat;
  my $lon;
  my $faz;
  my $speed;
  my $lasttime;
  if (ref($pt0) eq "Net::GPSD::Point") {
    $lat=$pt0->lat;
    $lon=$pt0->lon;
    $faz=$pt0->heading;
    $speed=$pt0->speed;
    $lasttime=$pt0->time;
  } else {
    $lat=$self->lat;
    $lon=$self->lon;
    $faz=$self->heading;
    $speed=$self->speed;
    $lasttime=undef();
  }
  if (defined $lasttime) {
    my $dist=$speed * ($lasttime-$time);
    ($lat,$lon,$faz) = $object->forward($lat,$lon,$faz,$dist);
    $faz-=180;
  }
  my $point=Net::GPSD::Point->new();
  $point->tag(ref($self));
  $point->time($time);
  $point->errortime(0.001);
  $point->lat($lat);
  $point->lon($lon);
  $point->speed($speed);
  $point->heading($faz);
  $point->mode(2);

  return $point;
}

sub getsatellitelist {
  use Net::GPSD::Satellite;
  return (Net::GPSD::Satellite->new(split " ", "0 1 2 3 4"));
}

sub lat {
  my $self = shift();
  if (@_) { $self->{'lat'} = shift() } #sets value
  return $self->{'lat'};
}

sub lon {
  my $self = shift();
  if (@_) { $self->{'lon'} = shift() } #sets value
  return $self->{'lon'};
}

sub speed {
  my $self = shift();
  if (@_) { $self->{'speed'} = shift() } #sets value
  return $self->{'speed'};
}

sub heading {
  my $self = shift();
  if (@_) { $self->{'heading'} = shift() } #sets value
  return $self->{'heading'};
}

1;
__END__

=pod

=head1 NAME

Net::GPSD::Server::Fake::Stationary - Provides a linear feed for the GPSD Daemon.

=head1 SYNOPSIS

 use Net::GPSD::Server::Fake;
 use Net::GPSD::Server::Fake::Track;
 my $server=Net::GPSD::Server::Fake->new();
 my $track=Net::GPSD::Server::Fake::Track->new(lat=>38.865826,
                                               lon=>-77.108574,
                                               speed=>25,
                                               heading=>45.3);
 $server->start($track);

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

Returns a new provider that can be passed to Net::GPSD::Server::Fake.

=item get

Returns a Net::GPSD::Point object

=item getsatellitelist

Returns a list of Net::GPSD::Satellite objects

=back

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

Only knows l and w commands

=head1 BUGS

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 SEE ALSO

gpsd home http://gpsd.berlios.de/

=cut

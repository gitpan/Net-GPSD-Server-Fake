package Net::GPSD::Server::Fake::Track;

=pod

=head1 NAME

Net::GPSD::Server::Fake::Track - Provides a linear feed for the GPSD Daemon.

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

=cut

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q{Revision: 0.10} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

Returns a new provider that can be passed to Net::GPSD::Server::Fake.

 my $track=Net::GPSD::Server::Fake::Track->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
  my %param = @_;
  $self->lat($param{'lat'}           ||  39.5);
  $self->lon($param{'lon'}           || -77.5);
  $self->speed($param{'speed'}       ||  20);
  $self->heading($param{'heading'}   ||  0);
}

=head2 get

Returns a Net::GPSD::Point object

  my $point=$obj->get;

=cut

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
  my $baz;
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
    ($lat,$lon,$baz) = $object->forward($lat,$lon,$faz,$dist);
    $faz=$baz-180;
  }
  my $point=Net::GPSD::Point->new();
  $point->tag("FAKE");
  $point->time($time);
  $point->errortime(0.001);
  $point->lat($lat);
  $point->lon($lon);
  $point->speed($speed);
  $point->heading($faz);
  $point->mode(2);

  return $point;
}

=head2 getsatellitelist

Returns a list of Net::GPSD::Satellite objects

  my @list=$obj->getsatellitelist;

=cut

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

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

=head1 BUGS

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Net::GPSD

=cut

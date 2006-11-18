#Copyright (c) 2006 Michael R. Davis (mrdvt92)
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package Net::GPSD::Server::Fake;

use strict;
use vars qw($VERSION);
use IO::Socket::INET;

$VERSION = sprintf("%d.%02d", q{Revision: 0.02} =~ /(\d+)\.(\d+)/);

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
  $self->port($param{'port'}         || '2947');
  $self->name($param{'name'} || 'GPSD');
}

sub start {
  my $self=shift();
  my %param = @_;
  $self->lat($param{'lat'}           ||  39.5);
  $self->lon($param{'lon'}           || -77.5);
  $self->speed($param{'speed'}       ||  25.2);
  $self->heading($param{'heading'}   ||  80.5);
  $SIG{CHLD} = 'IGNORE';
  my $listen_socket = IO::Socket::INET->new(LocalPort=>$self->port,
                                            Listen=>10,
                                            Proto=>'tcp',
                                            Reuse=>1);

  die "Can't create a listening socket: $@" unless $listen_socket;

  while ($listen_socket->opened and my $connection = $listen_socket->accept) {
    my $child;
    die "Can't fork: $!" unless defined ($child = fork());
    if ($child == 0) {       #i'm the child!
      $listen_socket->close; #only parent needs listening socket
      my $chars="";
      my $w=0;
      my $watcher_pid=undef();
      my $name=$self->name;
      while (my $data=$connection->getline) {
        next unless $data=~/\S/;       # blank line
        if    ($data=~m/l/i) {
          print $connection "$name,L=0 $VERSION lw Net-GPSD-Server-Fake\n";
        } elsif ($data=~m/w/i) {
          $w=$w?0:1;
          print $connection "$name,W=$w\n";
          if ($w) {
            $watcher_pid=$self->start_watcher($connection);
          } else {
            $self->stop_watcher($watcher_pid);
          }
        } else {
        }
      }
    } else { #i'm the parent
      $connection->close();
    }
  }
}

sub start_watcher {
  my $self=shift();
  my $fh=shift();
  my $pid=fork();
  die("Error: Cannot fork.") unless defined $pid;
  if ($pid) {
    return $pid;
  } else {
    $self->watcher($fh);
  }
}

sub stop_watcher {
  my $self=shift();
  my $pid=shift();
  kill "HUP", $pid;
}

sub watcher {
  my $self=shift();
  my $fh=shift();
  
  use Geo::Forward;
  use Time::HiRes qw{time};
  my $object = Geo::Forward->new();
  my $lasttime=undef;
  my $time=time;
  my $lat=$self->lat;
  my $lon=$self->lon;
  my $faz=$self->heading;
  my $speed=$self->speed;

  while (1) {
    $time=time;
    if (defined $lasttime) {
      my $dist=$speed * ($lasttime-$time);
      ($lat,$lon,$faz) = $object->forward($lat,$lon,$faz,$dist);
      $faz-=180;
    }
    print $fh $self->name,",O=FAKE $time 0.005 $lat $lon ? ? ? $faz $speed 0 ? ? ? 2\n";
    $lasttime=$time;
    sleep 1;
  }
}

sub name {
  my $self = shift();
  if (@_) { $self->{'name'} = shift() } #sets value
  return $self->{'name'};
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

sub port {
  my $self = shift();
  if (@_) { $self->{'port'} = shift() } #sets value
  return $self->{'port'};
}

1;
__END__

=pod

=head1 NAME

Net::GPSD::Server::Fake - Provides a Fake GPSD test harness. 

=head1 SYNOPSIS

 use Net::GPSD::Server::Fake;
 my $port=shift()||q{2947};
 my $server=Net::GPSD::Server::Fake->new(port=>$port)
               || die("Error: Cannot create server object.");
 $server->start(lat=>38.865826,
                lon=>-77.108574,
                speed=>25,
                heading=>45.3);

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

Returns a new server

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

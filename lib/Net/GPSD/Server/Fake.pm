#Copyright (c) 2006 Michael R. Davis (mrdvt92)
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package Net::GPSD::Server::Fake;

use strict;
use vars qw($VERSION);
use IO::Socket::INET;

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
  $self->port($param{'port'} || '2947');
  $self->name($param{'name'} || 'GPSD');
}

sub start {
  my $self=shift();
  my $provider=shift();
  $SIG{CHLD} = 'IGNORE';
  my $listen_socket = IO::Socket::INET->new(LocalPort=>$self->port,
                                            Listen=>10,
                                            Proto=>'tcp',
                                            Reuse=>1);

  die "Can't create a listening socket: $@" unless $listen_socket;

  while ($listen_socket->opened and my $connection=$listen_socket->accept) {
    my $child;
    die "Can't fork: $!" unless defined ($child = fork());
    if ($child == 0) {       #i'm the child!
      $listen_socket->close; #only parent needs listening socket
      my $chars="";
      my $w=0;
      my $watcher_pid=undef();
      my $name=$self->name;
      while (defined($_=$connection->getline)) {
        next unless m/\S/;       # blank line
        if    (m/l/i) {
          print $connection "$name,L=0 $VERSION lw ".ref($self)."\n";
        } elsif (m/w/i) {
          $w=$w?0:1;
          print $connection "$name,W=$w\n";
          if ($w) {
            $watcher_pid=$self->start_watcher($connection,$provider);
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
  my $provider=shift();
  my $pid=fork();
  die("Error: Cannot fork.") unless defined $pid;
  if ($pid) {
    return $pid;
  } else {
    $self->watcher($fh, $provider);
  }
}

sub stop_watcher {
  my $self=shift();
  my $pid=shift();
  kill "HUP", $pid;
}

sub watcher {
  use Time::HiRes qw{time};
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $point=undef();
  my $satellite=undef();
  my $count=0;

  while (1) {
    my $time=time;
    $point=$provider->point($time, $point);
    if (ref($point) eq "Net::GPSD::Point") {
    print $fh $self->name,",O=", 
      join(" ", $point->tag||"FAKE", $point->time||$time,
                $point->errortime||0.001, u2q($point->lat), u2q($point->lon),
                u2q($point->alt), u2q($point->errorhorizontal),
                u2q($point->errorvertical), u2q($point->heading),
                u2q($point->speed), u2q($point->climb),
                u2q($point->errorheading), u2q($point->errorspeed),
                u2q($point->errorclimb), u2q($point->mode)), "\n";
    } else {
      die("Error: provider->point must return Net::GPSD::Point not ". ref($point).".\n");
    }
    if ($count++ % 5 == 0) {
      $satellite=$provider->satellite();
      if (ref($satellite) eq "Net::GPSD::Satellite") {
        print ref($satellite), "\n";
      }
    }
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

sub u2q {
  my $value=shift();
  return (!defined($value)||($value eq "")) ? "?" : $value;
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

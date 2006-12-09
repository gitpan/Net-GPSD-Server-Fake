package Net::GPSD::Server::Fake;

=pod

=head1 NAME

Net::GPSD::Server::Fake - Provides a Fake GPSD daemon server test harness. 

=head1 SYNOPSIS

 use Net::GPSD::Server::Fake;
 use Net::GPSD::Server::Fake::Stationary;
 my $server=Net::GPSD::Server::Fake->new();
 my $stationary=Net::GPSD::Server::Fake::Stationary->new(lat=>38.865826,
                                                         lon=>-77.108574);
 $server->start($stationary);

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use IO::Socket::INET;

$VERSION = sprintf("%d.%02d", q{Revision: 0.11} =~ /(\d+)\.(\d+)/);

=head2 new

Returns a new server

  my $server=Net::GPSD::Server::Fake->new();

=cut

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
  $self->{'port'}=($param{'port'} || '2947');
  $self->name($param{'name'} || 'GPSD');
}

=head2 start

Binds provider to port and starts server.

 $server->start($provider);

=cut

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
      print "Connected: ", $connection->sockhost, ":", $connection->sockport, " -> ", $connection->peerhost,":",$connection->peerport, "\n";
      while (defined($_=$connection->getline)) {
        chomp;
        print "Command: ", $connection->peerhost,":",$connection->peerport, " -> ",$_,"\n";
        next unless m/\S/;       # blank line
        if    (m/l/i) {
          print $connection "$name,L=0 $VERSION ailopwy ".ref($self)."\n";
        } elsif (m/a/i) {
          my $point=$provider->get();
          print $connection "$name,A=", 
                            u2q(defined($point) ? $point->alt : '?'),"\n";
        } elsif (m/i/i) {
          my $point=$provider->get();
          print $connection "$name,I=", u2q(ref($provider)),"\n";
        } elsif (m/m/i) {
          my $point=$provider->get();
          print $connection "$name,M=", 
                            u2q(defined($point) ? $point->mode : '?'),"\n";
        } elsif (m/p/i) {
          my $point=$provider->get();
          print $connection "$name,P=",join(" ", 
                            u2q(defined($point) ? $point->lat : '?'),
                            u2q(defined($point) ? $point->lon : '?')
                            ), "\n";
        } elsif (m/o/i) {
          $self->print_o($provider, $connection);
        } elsif (m/y/i) {
          $self->print_y($provider, $connection);
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

sub print_o {
  my $self=shift();
  my $provider=shift();
  my $fh=shift();
  my $point=shift()||undef();
  my $time=shift()||time();
  $point=$provider->get($time, $point);
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
    die("Error: provider->get must return Net::GPSD::Point\n");
  }
}
sub print_y {
  my $self=shift();
  my $provider=shift();
  my $fh=shift();
  my @satellite=$provider->getsatellitelist();
  if (ref($satellite[0]) eq "Net::GPSD::Satellite") {
    print $fh $self->name,",Y=",
      join(" ", "FAKE",time,scalar(@satellite)),":",
      join(":", map {$_->prn, $_->elev, $_->azim, $_->snr,
                     $_->used} @satellite), "\n";
  } else {
    die("Error: provider->getsatellitelist must return a list of Net::GPSD::Satellite objects.\n");
  }
}

sub watcher {
  use Time::HiRes qw{time};
  my $self=shift();
  my $fh=shift();
  my $provider=shift();
  my $point=undef();
  my $count=0;

  while (1) {
    $self->print_o($provider, $fh, $point);
    if ($count++ % 5 == 0) {
      $self->print_y($provider, $fh);
    }
    sleep 1;
  }
}

=head2 name

Gets or sets GPSD protocol name. This defaults to "GPSD" as some clients are picky.

  $obj->name('GPSD');
  my $name=$obj->name;

=cut

sub name {
  my $self = shift();
  if (@_) { $self->{'name'} = shift() } #sets value
  return $self->{'name'};
}

=head2 port

Returns the current TCP port.

  my $port=$obj->port;

=cut

sub port {
  my $self = shift();
  return $self->{'port'};
}

sub u2q {
  my $value=shift();
  return (!defined($value)||($value eq "")) ? "?" : $value;
}

1;

__END__

=head1 GETTING STARTED

=head1 KNOWN LIMITATIONS

Only knows a few commands

Commands must be one per line.

Can't change providers mid stream.

Providers must remember state for watcher restarts.

Providers are queryed for a new point.  However, there needs to be a way for providers to be able to trigger new points.

=head1 BUGS

=head1 EXAMPLES

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

gpsd home http://gpsd.berlios.de/

=cut

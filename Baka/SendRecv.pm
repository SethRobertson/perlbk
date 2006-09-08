# -*- perl -*-
# $Id: SendRecv.pm,v 1.3 2006/09/08 22:19:04 jtt Exp $
#
# ++Copyright LIBBK++
#
# Copyright (c) 2003 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Mail <projectbaka\@baka.org> for further information
#
# --Copyright LIBBK--
#


##
# @file
#
package Baka::SendRecv;
@ISA = qw (Exporter);
@EXPORT_OK = qw ();
use Socket;
use IO::Socket;
use IO::Socket::INET;
use IO::Socket::UNIX;
use FreezeThaw qw(freeze thaw);
use Switch;
use strict;

use constant
{
  TYPE_ACTIVE		=>	"active",
  TYPE_PASSIVE		=>	"passive",
  DEFAULT_PROTOCOL	=>	"tcp",
  DEFAULT_PORT		=>	20001,
};

our $errstr;

# Special string which we use as our record separator so that instances of
# $/ (generally NEWLINE of course) which are embeded in our frozen string
# do not cause problems on the read side. This valus is modifiable by the
# user in case our chosen default actually occurs in their data (though
# binary data should always be uuencoded first). As you can plainly see,
# the default value is the "EOL" in octal.
our $eol = "\005\015\012"; 

{
  sub new($%)
  {
    my ($type, %args) = @_;
    my $self = {};
    my $socket;
    bless $self, $type;
    my ($lproto, $laddr, $lport);
    my ($rproto, $raddr, $rport);
    
    $self->{'errstr'} = "";
    $self->{'args'} = %args; # What the hell...

    if (!exists($args{'Type'}) || (($args{'Type'} ne TYPE_ACTIVE) && ($args{'Type'} ne TYPE_PASSIVE)))
    {
      $errstr = "Type => [" . TYPE_ACTIVE . "|" . TYPE_PASSIVE . "] is a required argument";
      return(undef);
    }
    
    $args{'LocalURL'} = "" if (!exists($args{'LocalURL'}));
    $args{'RemoteURL'} = "" if (!exists($args{'RemoteURL'}));
    if (!$self->_parse_url($args{'LocalURL'}, \$lproto, \$laddr, \$lport) ||
	!$self->_parse_url($args{'RemoteURL'}, \$rproto, \$raddr, \$rport))

    {
      $errstr = $self->errstr;
      return(undef);
    }

    if ($lproto ne $rproto)
    {
      $errstr = "The local and remote protocols do not match: ($lproto != $rproto)";
      return(undef);
    }

    my $proto = $lproto; # No longer any need to distinguish.

    if ($proto =~ /tcp|udp/) 
    {
      my %tcp_udp_args;

      $tcp_udp_args{'Proto'} = $proto;
      $tcp_udp_args{'Blocking'} = 1;
      $tcp_udp_args{'Type'} = ($proto eq "tcp")?SOCK_STREAM:SOCK_DGRAM;

      if ($args{'Type'} eq TYPE_ACTIVE)
      {
	if (!defined($raddr))
	{
	  $errstr = "The remote address must be specified for '" . TYPE_ACTIVE . "' INET connections";
	  return(undef);
	}

	$tcp_udp_args{'PeerAddr'} = "$raddr:" . (defined($rport)?"$rport":DEFAULT_PORT);
	if (defined($laddr))
	{
	  $tcp_udp_args{'LocalAddr'} = "$laddr" . (defined($lport)?":$lport":"");
	}
      }
      else
      {
	$tcp_udp_args{'LocalAddr'} = (defined($laddr)?"$laddr":inet_ntoa(INADDR_ANY)) . ":" . (defined($lport)?"$lport":DEFAULT_PORT);
	$tcp_udp_args{'ReuseAddr'} = 1;
	$tcp_udp_args{'Listen'} = 10;
      }

      if (!($socket = IO::Socket::INET->new(%tcp_udp_args)))
      {
	$errstr = "Could not create socket: $@";
	return(undef);
      }

      $self->{'socket'} = $socket;

      if ($args{'Type'} eq TYPE_PASSIVE)
      {
	my $client;

	if (!$socket->listen)
	{
	  $errstr = "Could not listen: $!";
	  return(undef);
	}
	
	if (!($client = $socket->accept))
	{
	  $errstr = "Failed to accept the connection: $!";
	  return(undef);
	}
	
	$socket->close;
	$self->{'socket'} = $client;
      }

    } 
    elsif ($proto =~ /local|unix/)
    {
      $self->{'proto'} = $proto;
    }
    else
    {
      $errstr = "Unknown protocol: $proto";
      return(undef);
    }
    
    return($self);
  }

  sub close($)
  {
    my($self) = @_;
    my ($socket, $key);
    
    if (!defined($socket = $self->{'socket'}))
    {
      $self->{'errstr'} = "No socket defined";
      return(0);
    }

    if (!$socket->close)
    {
      $self->{'errstr'} = "Could not close socket: $!";
      return(0);
    }
    
    foreach $key (keys %$self)
    {
      delete $self->{$key};
    }
    return(1);
  }



  sub errstr($)
  {
    my($self) = @_;
    return($self->{'errstr'});
  }



  sub print($)
  {
    my($self) = @_;
    my($socket);
    return "" if (!($socket = $self->{'socket'}));
    return("[" . $socket->sockhost . ":" . $socket->sockport . "|" . $socket->peerhost . ":" . $socket->peerport . "]");
  }



  sub send($@)
  {
    my($self, @things) = @_;
    my $socket;

    if (!defined($socket = $self->{'socket'}))
    {
      $self->{'errstr'} = "No socket defined";
      return(0);
    }

    return (0) if (!$self->_check_refs(@things));

    my $frozen_text = freeze(@things);

    my $old_eol=$/;
    $/ = $eol;
    my $result = $socket->print("$frozen_text$/");
    $/ = $old_eol;
    
    if (!$result)
    {
      $self->{'errstr'} = "Could not write out frozen data: $!";
      return(0);
    }

    return(1);
  }



  sub recv($@)
  {
    my($self, @wanted_things) = @_;
    my ($socket, $cnt);

    if (!defined($socket = $self->{'socket'}))
    {
      $self->{'errstr'} = "No socket defined";
      return(0);
    }

    return (0) if (!$self->_check_refs(@wanted_things));

    my $old_eol = $/;
    $/ = $eol;
    chomp(my $frozen_text = $socket->getline);
    $/ = $old_eol;

    my @received_things = thaw($frozen_text);

    if (@received_things != @wanted_things)
    {
      $self->{'errstr'} = "Received " . scalar(@received_things) . " things, expected " . scalar(@wanted_things);
      return(0);
    }

    for($cnt = 0; $cnt < @wanted_things; $cnt++)
    {
      switch (ref($wanted_things[$cnt]))
      {
	case "SCALAR" { ${$wanted_things[$cnt]} = ${$received_things[$cnt]}; }
	case "ARRAY" { @{$wanted_things[$cnt]} = @{$received_things[$cnt]}; }
	case "HASH" { %{$wanted_things[$cnt]} = %{$received_things[$cnt]}; }
      }
    }
    
    return(1);
  }



  sub _check_refs($@)
  {
    my($self, @array_of_refs) = @_;
    my $cnt;
    my @errors = ();

    for($cnt = 0; $cnt < @array_of_refs; $cnt++)
    {
      my $ref = ref($array_of_refs[$cnt]);

      if ($ref eq "")
      {
	push @errors, "Argument \#${cnt} is not a reference.";
	next;
      }

      if ($ref !~ /SCALAR|HASH|ARRAY/)
      {
	push @errors,  "Argument \#${cnt} is a $ref reference. which is not valid.";
	next;
      }
    }
    
    if (@errors)
    {
      $self->{'errstr'} = join("  ", @errors);
      return(0);
    }
    
    return(1);
  }



  ################################################################
  # Parse the url with a heave IP bias
  #
  sub _parse_url($$$$$)
  {
    my($self, $url, $proto_r, $address_r, $port_r) = @_;
    my($proto, $endpt);
    my($host, $port);
    
    $url =~ s/^\s+|\s+$//g if ($url); # Trim off whitespace (this should really be a perl function).
    # assume tcp://0.0.0.0:20001 as the default
    if (!$url)
    {
      $$proto_r = DEFAULT_PROTOCOL;
      return(1);
    }

    my(@proto_split) = split(m|://|, $url);

    if (@proto_split == 1)
    {
      ($$proto_r, $$address_r) = (DEFAULT_PROTOCOL, $url);
      return(1);
    }
    elsif (@proto_split == 2)
    {
      ($proto, $endpt) = @proto_split;
      
      $proto = lc($proto);
      if ($proto !~ /tcp|udp|local|unix/)
      {
	$self->{'errstr'} = "Invalid protocol: $proto";
	return(0);
      }
      
      $$proto_r = $proto;
    }
    else
    {
      $self->{'errstr'} = "Invalid URL: $url";
      return(0)
    }

    if ($proto =~ /tcp|udp/)
    {
      # Parse data a hostname:port pair
      ($host, $port) = split(/:/, $endpt);
      
      $$port_r = $port if (defined($port));
      $$address_r = $host if (defined($host));
    }
    else
    {
      # Parse data as a file name
      $$address_r = $endpt; 
    }

    return(1);
  }
};

1;

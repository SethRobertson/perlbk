# $Id: BkException.pl,v 1.2 2003/06/12 04:44:20 lindauer Exp $
#
# ++Copyright SYSDETECT++
#
# Copyright (c) 2001 System Detection.  All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SYSTEM DETECTION.
# The copyright notice above does not evidence any actual
# or intended publication of such source code.
# 
# Only properly authorized employees and contractors of System Detection
# are authorized to view, posses, to otherwise use this file.
# 
# System Detection
# 5 West 19th Floor 2 Suite K
# New York, NY 10011-4240
# 
# +1 212 242 2970
# <sysdetect@sysdetect.org>
# 
# --Copyright SYSDETECT--



##
# @file
# Error stack handling.
#



package BkException;
{
  sub new($)
  {
    my ($type, $errstr) = @_;
    my $self = {};
    bless $self, $type;
    $self->{'errstack'} = ();
    $self->push($errstr);
    return $self;
  }

  # Push an error onto the stack
  sub push($$)
  {
    my ($self, $errstr) = @_;
    return undef unless ($self->isa(BkException));
    push(@{$self->{'errstack'}}, $errstr);
  }

  # Pop an error off of the stack
  sub pop($)
  {
    my ($self) = @_;
    return $self unless ($self->isa(BkException));
    pop(@{$self->{'errstack'}});
  }

  # Peek at the error on top of the stack
  sub peek($)
  {
    my ($self) = @_;
    return $self unless ($self->isa(BkException));
    return $self->{'errstack'}[scalar(@{$self->{'errstack'}}) - 1];
  }

  # Format error stack and return string
  sub stringify($)
  {
    my ($self) = @_;
    my ($buf, $indent, $errstr);

    # Protect against unhandled perl exceptions
    return "$self\n" unless ($self->isa(BkException));

    $buf = "";
    $indent = "";

    while ($errstr = $self->pop())
    {
      $buf .= $indent . $errstr . "\n";
      $indent .= "  ";
    }

    return $buf;
  }
};



return 1;

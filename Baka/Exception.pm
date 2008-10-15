# 
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
# Error stack handling.
#



package Baka::Exception;
require Exporter;
@ISA = qw (Exporter);
@EXPORT_OK = qw(push pop peek stringify);
$VERSION = 1.00;
{
  use UNIVERSAL qw(isa);

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
    return undef unless (isa($self, Baka::Exception));
    push(@{$self->{'errstack'}}, $errstr);
  }

  # Pop an error off of the stack
  sub pop($)
  {
    my ($self) = @_;
    return $self unless (isa($self, Baka::Exception));
    pop(@{$self->{'errstack'}});
  }

  # Peek at the error on top of the stack
  sub peek($)
  {
    my ($self) = @_;
    return $self unless (isa($self, Baka::Exception));
    return undef unless (scalar(@{$self->{'errstack'}}) >= 1);
    return $self->{'errstack'}[scalar(@{$self->{'errstack'}}) - 1];
  }

  # Format error stack and return string
  sub stringify($)
  {
    my ($self) = @_;
    my ($buf, $indent, $errstr);

    # Protect against unhandled perl exceptions
    return "$self\n" unless (isa($self, Baka::Exception));

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

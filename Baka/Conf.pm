# $Id: Conf.pm,v 1.1 2003/12/31 16:56:18 lindauer Exp $
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
# Read bk.conf format file
#


package Baka::Conf;
require Exporter;
use FileHandle;
@ISA = qw (Exporter);
@EXPORT_OK = qw(get get_sections get_keys);
$VERSION = 1.00;
{
  sub new($)
  {
    my ($type, $filename) = @_;
    my ($fh, $line, $section);
    my $self = {};
    bless $self, $type;
    $self->{'filename'} = $filename;
    $self->{'sections'} = {};

    # Read the file
    $fh = new FileHandle;
    $fh->open("< $filename") || die "Failed to open $filename: $!.\n";

    $section = 'global';
    while ($line = <$fh>)
    {
      # strip the whitespace
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;

      next if ($line =~ /^\#/);
      next unless (length($line));

      if ($line =~ /^\[(.*)\]$/)
      {
	# new section
	$section = $1;
      }
      elsif ($line =~ /(\S+?)\s*=\s*(\S+)/)
      {
	my $key = $1;
	my $val = $2;

	$self->{'sections'}->{$section}->{$key} = $val;
      }
      else
      {
	die "Invalid line in conf file: '$line'";
      }
    }

    $fh->close();

    return $self;
  }


  # Lookup the value of a key.  Section is global unless specified.
  sub get($$$)
  {
    my ($self, $key, $section) = @_;

    $section = 'global' unless ($section);

    my $sec_hash = $self->{'sections'}->{$section};
    return undef unless ($sec_hash);

    return $sec_hash->{$key};
  }



  # return list of section names
  sub get_sections($)
  {
    my ($self) = @_;
    return keys(%{$self->{'sections'}});
  }



  # return list of keys in a section
  sub get_keys($$)
  {
    my ($self, $section) = @_;
    my $sec_hash = $self->{'sections'}->{$section};
    return undef unless ($sec_hash);

    return keys(%{$sec_hash});
  }
};



return 1;

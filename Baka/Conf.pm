# -*- perl -*-
# $Id: Conf.pm,v 1.2 2004/02/28 00:44:52 jtt Exp $
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
@EXPORT_OK = qw(get get_sections get_keys set_uniq_value);
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

  
  # Set a value in a simple baka conf with no sections and unique values
  # Return 1 on success, 0 on failure.
  sub set_uniq_value($$$)
  {
    my($self, $key, $value) = @_;
    my(@lines);
    my($found_key) = 0;
    my($ret) = 1;

    # Update myself
    $self{'sections'}{'global'}{$key} = $value;
    
    # Update the file. First read and replace the value if the key is found.
    open(CONF_IN, "< $self->{'filename'}") || die "Failed to open $self->{'filename'} for reading: $!.\n";
    @lines = grep(s/^\s*$key\s*=.*/$key = $value/ && ($found_key = 1) || 1, <CONF_IN>);
    close(CONF_IN);

    # Add the key/value pair if the key was not found
    push @lines, "$key = $value\n" if (!$found_key);

    # Write out new file.
    open(CONF_OUT, "> $self->{'filename'}+") || 
      die "Failed to open $self->{'filename'} for writing: $!.\n";

    print CONF_OUT "" . join ('', @lines);

    close(CONF_OUT);
    rename("$self->{'filename'}+", "$self->{'filename'}");
    return($ret);
  }
};



return 1;

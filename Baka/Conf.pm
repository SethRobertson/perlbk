# -*- perl -*-
# $Id: Conf.pm,v 1.10 2005/01/22 20:25:03 jtt Exp $
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
      elsif ($line =~ /^(\S+?)\s*=\s*(.*)$/)
      {
	my $key = $1;
	my $val = $2;

	$self->{'sections'}->{$section}->{$key} = $val
	  if (!defined $self->{'sections'}->{$section}->{$key});
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



  # Return the entire hash for a section.  Section is global unless specified.
  sub get_section($$)
  {
    my ($self, $section) = @_;

    $section = 'global' unless ($section);

    return $self->{'sections'}->{$section};
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
  sub set_uniq_value($$$;$)
  {
    my($self, $key, $value, $error_ref) = @_;
    my(@lines);
    my($found_key) = 0;
    my($ret) = 0;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);


    if (!defined($key))
    {
      $$error_ref = "Illegal arguments" if (defined($$error_ref));
      goto error;
    }

    if (!defined($value))
    {
      delete($self->{'sections'}->{'global'}->{$key});
      return 1;
    }
	     
    # Update myself
    $self->{'sections'}->{'global'}->{$key} = $value;

    # Update the file. First read and replace the value if the key is found.
    if (!open(CONF_IN, "< $self->{'filename'}"))
    {
      $$error_ref = "Failed to open $self->{'filename'} for reading: $!.\n" 
	if (defined($error_ref));
      goto error;
    }
    @lines = grep(s/^\s*(\#\s*)?$key\s*=.*/$key = $value/ && ($found_key = 1) || 1, <CONF_IN>);
    close(CONF_IN);

    # Add the key/value pair if the key was not found
    push @lines, "$key = $value\n" if (!$found_key);

    # Write out new file.
    if (!open(CONF_OUT, "> $self->{'filename'}+"))
    {
      $$error_ref = "Failed to open $self->{'filename'} for writing: $!.\n" 
	if (defined($$error_ref));
      goto error;
    }
    print CONF_OUT "" . join ('', @lines);

    close(CONF_OUT);

    # Copy permissions
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$self->{'filename'}");
    chown($uid, $gid, "$self->{'filename'}+");
    chmod($mode & 07777, "$self->{'filename'}+");

    if (!rename("$self->{'filename'}+", "$self->{'filename'}"))
    {
      $$error_ref = "Could not rename $self->{'filename'}+ to $self->{'filename'}: $!" if (defined($$error_ref));
      goto error;
    }

    $ret = 1;

  error:
    return($ret);
  }
};



return 1;

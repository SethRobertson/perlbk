######################################################################
#
# ++Copyright LIBBK++
#
# Copyright (c) $YEAR The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Mail <projectbaka\@baka.org> for further information
#
# --Copyright LIBBK--
#
# A standard reports helper
#

sub helper_ifconfig($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($interface);
  my (%interinfo);
  my ($oldinfo);

  my ($ifconfig);
  $ifconfig = `ifconfig -a`;
  if ($? != 0)
  {
    return "ifconfig command failed: $?\n";
  }

  $Output{'name'} = "Interface Status";
  $Output{'data'} = $ifconfig;

  # Parse the interface information
  foreach $interface (split(/\n\n/,$ifconfig))
  {
    if ($interface !~ /^(\S+)[^\n]+\n(\s+inet addr:(\S+)[^\n]+\n|)\s+(\S+)[^\n]+\n\s+RX\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)[^\n]*\n\s+TX\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)\s+(\S+):(\S+)[^\n]*\n\s+RX (\S+):(\d+).*TX (\S+):(\d+)/)
    {
      return "Non-matching interface line $interface\n";
    }

    $interinfo{$1}->{"status"} = $4;
    $interinfo{$1}->{"RX-$5"} = $6;
    $interinfo{$1}->{"RX-$7"} = $8;
    $interinfo{$1}->{"RX-$9"} = $10;
    $interinfo{$1}->{"RX-$11"} = $12;
    $interinfo{$1}->{"RX-$13"} = $14;

    $interinfo{$1}->{"TX-$15"} = $16;
    $interinfo{$1}->{"TX-$17"} = $18;
    $interinfo{$1}->{"TX-$19"} = $20;
    $interinfo{$1}->{"TX-$21"} = $22;
    $interinfo{$1}->{"TX-$23"} = $24;
    $interinfo{$1}->{"TX-$25"} = $26;
    $interinfo{$1}->{"TX-$27"} = $28;

    $interinfo{$1}->{"RX-$29"} = $30;
    $interinfo{$1}->{"TX-$31"} = $32;
  }


# Debugging
#  my ($x,$y);
#  foreach $x (sort keys %interinfo)
#  {
#    foreach $y (sort keys %{$interinfo{$x}})
#    {
#      $Output{'data'} .= "$x $y $interinfo{$x}->{$y}\n";
#    }
#  }

  # Check for surprising changes
  if ($Storedref->{'helper_ifconfig_init'})
  {
    my ($int);

    $oldinfo = $Storedref->{'helper_ifocnfig_intinfo'};
    foreach $int (keys %interinfo)
    {
      if (!$oldinfo->{$int})
      {
	push(@warnings,"New interface $int has appeared!\n");
	next;
      }

      if ($interinfo{$int}->{'status'} ne $oldinfo->{$int}->{'status'})
      {
	push(@warnings,"Interface $int has changed status from $oldinfo->{$int}->{'status'} to $interinfo{$int}->{'status'}!\n");
	next;
      }
    }
    foreach $int (keys %$oldinfo)
    {
      if (!$interinfo{$int})
      {
	push(@warnings,"Old interface $int has disappeared!\n");
	next;
      }
    }
  }

  $Storedref->{'helper_ifconfig_init'} = 1;

  $Storedref->{'helper_ifconfig_intinfo'} = \%interinfo;

  push(@$Outputarrayref, \%Output);

  1;
}

1;

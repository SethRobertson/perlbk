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
# <description>A module which will display the results of `ifconfig
# -a`.  In addition, it will track the various interface statistics
# available in ifconfig -a and will alert if the error statistics go
# up, or the non-error statistics (packet/byte counts) do not go up.
# Note that packet/byte counts alerts might generate FPs for very
# active sites.</description>

sub helper_ifconfig($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($interface);
  my (%interinfo);
  my ($oldinfo);
  my ($confidence) = 1;

  my ($ifconfig);
  $ifconfig = `ifconfig -a`;
  if ($? != 0)
  {
    return "ifconfig command failed: $?\n";
  }

  $Output{'name'} = "Interface Status";
  $Output{'id'} = "ifconfig";
  $Output{'data'} = $ifconfig;

  # Parse the interface information
  foreach $interface (split(/\n\n/,$ifconfig))
  {
    if ($interface !~ /^(\S+)[^\n]+\n(\s+inet addr:(\S+)[^\n]+\n|)(?:\s+inet6 addr: [^\n]+\n)*(?# flags)\s+(\S+)[^\n]+\n(?:\s+RX\s+(?# packets)(\S+):(\S+)\s+(?# errors)(\S+):(\S+)\s+(?# dropped)(\S+):(\S+)\s+(?# overruns)(\S+):(\S+)\s+(?# frame)(\S+):(\S+)[^\n]*\n\s+TX\s+(?# packets)(\S+):(\S+)\s+(?# errors)(\S+):(\S+)\s+(?# dropped)(\S+):(\S+)\s+(?# overruns)(\S+):(\S+)\s+(?# carrier)(\S+):(\S+)\s+(?# Collisions)(\S+):(\S+)\s+(?# txqueuelen)(\S+):(\S+)[^\n]*\n\s+RX (?# bytes)(\S+):(\d+).*TX (?# bytes)(\S+):(\d+))?/)
    {
      return "Non-matching interface line $interface\n";
    }

    $interinfo{$1}->{"status"} = $4;
    # get stats for non-alias interfaces
    if ($1 !~ /:/)
    {
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

    $oldinfo = $Storedref->{'helper_ifconfig_intinfo'};
    foreach $int (keys %interinfo)
    {
      next if ($Opt->{'alert'} && ($int !~ /$Opt->{'alert'}/));

      if (!$oldinfo->{$int})
      {
	push(@warnings,"New interface $int has appeared!\n");
	$confidence -= .05;
	next;
      }

      if ($interinfo{$int}->{'status'} ne $oldinfo->{$int}->{'status'})
      {
	push(@warnings,"Interface $int has changed status from $oldinfo->{$int}->{'status'} to $interinfo{$int}->{'status'}!\n");
	if ($interinfo{$int}->{'status'} eq "UP")
	{
	  $confidence -= .05;
	}
	else
	{
	  $confidence -= .5;
	}
	next;
      }

      # Don't bother looking further at non-up or alias interfaces
      next if ($interinfo{$int}->{'status'} ne "UP" || $int =~ /:/);

      if ($interinfo{$int}->{'RX-packets'} == $oldinfo->{$int}->{'RX-packets'})
      {
	push(@warnings,"Interface $int has not received additional packets, was $oldinfo->{$int}->{'RX-packets'} now $interinfo{$int}->{'RX-packets'}!\n");
	$confidence -= .1;
	next;
      }

      if ($interinfo{$int}->{'RX-bytes'} == $oldinfo->{$int}->{'RX-bytes'})
      {
	push(@warnings,"Interface $int has not received additional data (but did receive some packets), was $oldinfo->{$int}->{'RX-bytes'} now $interinfo{$int}->{'RX-bytes'}!\n");
	$confidence -= .2;
	next;
      }
#
#      if ($interinfo{$int}->{'RX-dropped'} > $oldinfo->{$int}->{'RX-dropped'})
#      {
#	push(@warnings,"Interface $int dropped some packets on reception, was $oldinfo->{$int}->{'RX-dropped'} now $interinfo{$int}->{'RX-dropped'}!\n");
#	$confidence -= .02;
#	next;
#      }
#
#      if ($interinfo{$int}->{'RX-errors'} > $oldinfo->{$int}->{'RX-errors'})
#      {
#	push(@warnings,"Interface $int received some errors, was $oldinfo->{$int}->{'RX-errors'} now $interinfo{$int}->{'RX-errors'}!\n");
#	$confidence -= .1;
#	next;
#      }
#
#      if ($interinfo{$int}->{'RX-frame'} > $oldinfo->{$int}->{'RX-frame'})
#      {
#	push(@warnings,"Interface $int received some frame problems, was $oldinfo->{$int}->{'RX-frame'} now $interinfo{$int}->{'RX-frame'}!\n");
#	$confidence -= .1;
#	next;
#      }
#
#      if ($interinfo{$int}->{'RX-overruns'} > $oldinfo->{$int}->{'RX-overruns'})
#      {
#	push(@warnings,"Interface $int saw some overruns (not unusual), was $oldinfo->{$int}->{'RX-overruns'} now $interinfo{$int}->{'RX-overruns'}!\n");
#	$confidence -= .01;
#	next;
#      }
#
#      if ($interinfo{$int}->{'TX-carrier'} > $oldinfo->{$int}->{'TX-carrier'})
#      {
#	push(@warnings,"Interface $int has some carrier problems (not a major problem), was $oldinfo->{$int}->{'TX-carrier'} now $interinfo{$int}->{'TX-carrier'}!\n");
#	$confidence -= .01;
#	next;
#      }
#
#      if ($interinfo{$int}->{'TX-collisions'} > $oldinfo->{$int}->{'TX-collisions'})
#      {
#	push(@warnings,"Interface $int saw some collisions (not usually major problem, consider moving to a switch), was $oldinfo->{$int}->{'TX-collisions'} now $interinfo{$int}->{'TX-collisions'}!\n");
#	$confidence -= .001;
#	next;
#      }
#
#      if ($interinfo{$int}->{'TX-dropped'} > $oldinfo->{$int}->{'TX-dropped'})
#      {
#	push(@warnings,"Interface $int dropped packets on transmit, was $oldinfo->{$int}->{'TX-dropped'} now $interinfo{$int}->{'TX-dropped'}!\n");
#	$confidence -= .05;
#	next;
#      }
#
#      if ($interinfo{$int}->{'TX-errors'} > $oldinfo->{$int}->{'TX-errors'})
#      {
#	push(@warnings,"Interface $int had errors on transmit, was $oldinfo->{$int}->{'TX-errors'} now $interinfo{$int}->{'TX-errors'}!\n");
#	$confidence -= .2;
#	next;
#      }
#
#      if ($interinfo{$int}->{'TX-overruns'} > $oldinfo->{$int}->{'TX-overruns'})
#      {
#	push(@warnings,"Interface $int had overruns on transmit (not unusual), was $oldinfo->{$int}->{'TX-overruns'} now $interinfo{$int}->{'TX-overruns'}!\n");
#	$confidence -= .05;
#	next;
#      }
    }
    foreach $int (keys %$oldinfo)
    {
      if (!$interinfo{$int})
      {
	push(@warnings,"Old interface $int has disappeared!\n");
	$confidence -= .5;
	next;
      }
    }
  }
  $Output{'operating'} = 1;

  $Storedref->{'helper_ifconfig_init'} = 1;

  $Storedref->{'helper_ifconfig_intinfo'} = \%interinfo;

  push(@$Outputarrayref, \%Output);

  $Out1{'id'} = "Interface Warnings";
  push(@$Outputarrayref, \%Out1);
  if ($#warnings >= 0)
  {
    my (%Out1);

    $Out1{'operating'} = $confidence<0?0:$confidence;
    $Out1{'name'} = "Interface Warnings";
    $Out1{'data'} = join("",@warnings);;
  }

  1;
}

1;

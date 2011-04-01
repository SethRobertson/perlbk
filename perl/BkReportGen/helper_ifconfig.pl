######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2011 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
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
    if ($interface !~ /^(\S+)[^\n]+\n(\s+inet addr:(\S+)[^\n]+\n|)(?:\s+inet6 addr: [^\n]+\n)*(?# flags)\s+((\S+)[^\n]*?)  [^\n]+\n(?:\s+RX\s+(?# packets)(\S+):(\S+)\s+(?# errors)(\S+):(\S+)\s+(?# dropped)(\S+):(\S+)\s+(?# overruns)(\S+):(\S+)\s+(?# frame)(\S+):(\S+)[^\n]*\n\s+TX\s+(?# packets)(\S+):(\S+)\s+(?# errors)(\S+):(\S+)\s+(?# dropped)(\S+):(\S+)\s+(?# overruns)(\S+):(\S+)\s+(?# carrier)(\S+):(\S+)\s+(?# Collisions)(\S+):(\S+)\s+(?# txqueuelen)(\S+):(\S+)[^\n]*\n\s+RX (?# bytes)(\S+):(\d+).*TX (?# bytes)(\S+):(\d+))?/)
    {
      return "Non-matching interface line $interface\n";
    }

    $interinfo{$1}->{"status"} = $5;
    $interinfo{$1}->{"flags"} = $4;
    # get stats for non-alias interfaces
    if ($1 !~ /:/)
    {
      $interinfo{$1}->{"RX-$6"} = $7;
      $interinfo{$1}->{"RX-$8"} = $9;
      $interinfo{$1}->{"RX-$10"} = $11;
      $interinfo{$1}->{"RX-$12"} = $13;
      $interinfo{$1}->{"RX-$14"} = $15;

      $interinfo{$1}->{"TX-$16"} = $17;
      $interinfo{$1}->{"TX-$18"} = $19;
      $interinfo{$1}->{"TX-$20"} = $21;
      $interinfo{$1}->{"TX-$22"} = $23;
      $interinfo{$1}->{"TX-$24"} = $25;
      $interinfo{$1}->{"TX-$26"} = $27;
      $interinfo{$1}->{"TX-$28"} = $29;

      $interinfo{$1}->{"RX-$30"} = $31;
      $interinfo{$1}->{"TX-$32"} = $33;
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
      # skip interfaces not on the alert list, unless a bonding interface is on
      # the alert list and interface is a SLAVE
      next if (!$Opt->{'alert'} ||
	       ($int !~ /$Opt->{'alert'}/ &&
		($Opt->{'alert'} !~ /\bbond\d+\b/ ||
		 $interinfo{$int}->{'flags'} !~ /\bSLAVE\b/)));

      if (!$oldinfo->{$int})
      {
	push(@warnings,"New interface $int has appeared!\n");
	$confidence -= .05;
	next;
      }

      if ($interinfo{$int}->{'status'} ne $oldinfo->{$int}->{'status'})
      {
	push(@warnings,"Interface $int has changed admin status from $oldinfo->{$int}->{'status'} to $interinfo{$int}->{'status'}!\n");
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

      if ($interinfo{$int}->{'flags'} !~ /\bRUNNING\b/)
      {
	if ($interinfo{$int}->{'flags'} !~ /\bSLAVE\b/)
	{
	  my $bondmsg = "";

	  # This is a primary interface - if it is the only one on the alert
	  # list the operational state is 0%, otherwise 50%
	  if ($Opt->{'alert'} =~ /\|/)
	  {
	    $confidence -= .5;
	    $bondmsg = " (all bonded interfaces down)" if ($int =~ /^bond\d/);
	  }
	  else
	  {
	    $confidence = 0;
	    $bondmsg = " (all monitoring interfaces down)" if ($int =~ /^bond\d/);
	  }

	  push(@warnings,"Interface $int has no link$bondmsg!!\n");
	}
	elsif ($interinfo{$int}->{'flags'} ne $oldinfo->{$int}->{'flags'})
	{
	  # Slave interface without link reduces health only if previously up
	  $confidence -= .2;
	  push(@warnings,"Interface $int has no link!\n was '$oldinfo->{$int}->{'flags'}',\n now '$interinfo{$int}->{'flags'}'\n");
	  push(@warnings,`egrep -i "^\$(date +'\%b \%e').* $int.* (up|down)" /var/log/messages | grep -v bond | tail`)
	}
	next;
      }

      my ($rxdelta) = $interinfo{$int}->{'RX-packets'} - $oldinfo->{$int}->{'RX-packets'};

      if (!$rxdelta)
      {
	push(@warnings,"Interface $int has not received additional packets, still $interinfo{$int}->{'RX-packets'}!\n");
	# Slaves are only sick if traffic previously seen, but not in 24 hours
	if ($interinfo{$int}->{'flags'} !~ /\bSLAVE\b/ || ($Inforef->{'PeriodSeconds'} > 86000 && $oldinfo->{$int}->{'RX-packets'} > 0))
	{
	  $confidence -= .1;
	  next;
	}
      }
      elsif ($rxdelta < 0)
      {
	# interface counters reset - reboot or ifdown/ifup - don't report
	# nonsensical drop/err/frame etc. warnings based on negative counts
	next;
      }

      if ($interinfo{$int}->{'RX-bytes'} == $oldinfo->{$int}->{'RX-bytes'})
      {
	push(@warnings,"Interface $int has not received additional data, still $interinfo{$int}->{'RX-bytes'} bytes (received ".($interinfo{$int}->{'RX-packets'} - $oldinfo->{$int}->{'RX-packets'})." packets)!");
	# Slaves are only sick if traffic previously seen, but not in 24 hours
	if ($interinfo{$int}->{'flags'} !~ /\bSLAVE\b/ || ($Inforef->{'PeriodSeconds'} > 86000 && $oldinfo->{$int}->{'RX-bytes'} > 0))
	{
	  $confidence -= .2;
	  next;
	}
      }

      # don't count errors on bond, as they will increase if any slave increases
      # (unlike traffic health which is bad only if _all_ slaves see no traffic)
      next if ($int =~ /^bond\d/);

      my ($rxdropdelta) = 0;
      if (defined($interinfo{$int}->{'RX-dropped'}) && defined($oldinfo->{$int}->{'RX-dropped'}))
      {
	$rxdropdelta = $interinfo{$int}->{'RX-dropped'} - $oldinfo->{$int}->{'RX-dropped'};
	my ($rxdroppct) = 0;
	$rxdroppct = 100*$rxdropdelta/($rxdelta+$rxdropdelta)
	  if ($rxdelta+$rxdropdelta);

	if ($rxdroppct >= 1)
	{
	  push(@warnings,sprintf("Interface %s dropped %d (%.3f%%) packets on reception, was %d now %d!\n",$int,$rxdropdelta,$rxdroppct,$oldinfo->{$int}->{'RX-dropped'},$interinfo{$int}->{'RX-dropped'}));
	  $confidence -= .02;
	  next;
	}
      }

      my ($rxerrdelta) = 0;
      if (defined($interinfo{$int}->{'RX-errors'}) && defined($oldinfo->{$int}->{'RX-errors'}))
      {
	my ($rxerrdelta) = $interinfo{$int}->{'RX-errors'} - $oldinfo->{$int}->{'RX-errors'};
	my ($rxerrpct) = 0;
	$rxerrpct = 100*$rxerrdelta/($rxdelta+$rxerrdelta+$rxdropdelta)
	  if ($rxdelta+$rxerrdelta+$rxdropdelta);

	if ($rxerrpct >= 1)
	{
	  push(@warnings,sprintf("Interface %s had %d receive errors (%.3f%%), was %d now %d!\n",$int,$rxerrdelta,$rxerrpct,$oldinfo->{$int}->{'RX-errors'},$interinfo{$int}->{'RX-errors'}));
	  $confidence -= .01;
	  next;
	}
      }

      my ($rxframedelta) = 0;
      if (defined($interinfo{$int}->{'RX-frame'}) && defined($oldinfo->{$int}->{'RX-frame'}))
      {
	$rxframedelta = $interinfo{$int}->{'RX-frame'} - $oldinfo->{$int}->{'RX-frame'};
	my ($rxframepct) = 0;
	$rxframepct = 100*$rxframedelta/($rxdelta+$rxframedelta+$rxerrdelta+$rxdropdelta)
	  if ($rxdelta+$rxframedelta+$rxerrdelta+rxdropdelta);

	if ($rxframepct >= 1)
	{
	  push(@warnings,sprintf("Interface %s had %d framing errors (%.3f%%), was %d now %d!\n",$int,$rxframedelta,$rxframepct,$oldinfo->{$int}->{'RX-frame'},$interinfo{$int}->{'RX-frame'}));
	  $confidence -= .01;
	  next;
	}
      }

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

  my %Out1;
  $Out1{'id'} = "Interface Warnings";
  push(@$Outputarrayref, \%Out1);
  if ($#warnings >= 0)
  {
    $Out1{'operating'} = $confidence<0?0:$confidence;
    $Out1{'name'} = "Interface Warnings";
    $Out1{'data'} = join("",@warnings);;
  }

  1;
}

1;

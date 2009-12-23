######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2005-2008 The Authors. All rights reserved.
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
# <description>Run BMC health and reporting tests.</description>

sub helper_bmc($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my $bmc = '';
  my %Output;

  $Output{'id'} = "bmc";
  $Output{'operating'} = 1.0;
  # set name to BMC or iDRAC6
  push(@$Outputarrayref, \%Output);

  if (-c '/dev/ipmi0')
  {
    $Output{'name'} = `ipmitool sdr elist mcloc 2>/dev/null`;
    $Output{'name'} =~ s/  .*/ /s;

    $_ = `ipmitool chassis status`;
    $bmc .= "Chassis status:\n";
    $bmc .= $_;
    if (/(.*(Fault|Overload).*?)\s*:\s(?!false)/)
    {
      $Output{'operating'} = .3;
      $Output{'name'} .= "$1 ";
    }

    # create SDR cache file - speeds up checks a bit
    my $cache = "/var/tmp/ipmitool.sdr.cache";
    if (-s $cache || system("ipmitool sdr dump $cache >/dev/null"))
    {
      $cache = "-S $cache";
    }
    else
    {
      $cache = "";
    }

    # get list of sensor types actually implemented - huge speedup for PEx950
    my $types = "/var/tmp/ipmitool.sdr.types";
    my @types;
    my @ntypes = ();
    if (-s $types)
    {
      @types = `cat $types`;
    }
    else
    {
      foreach $_ (`ipmitool $cache sdr type list`)
      {
	next if (/^\S.*:$/);
	s/^\s*(.*?)\s*$/$1/;
	my ($ta, $tb) = split /   */;
	push(@types, "$ta\n");
	push(@types, "$tb\n");
      }
    }

    $bmc .= "\nSensor status:\n";
    foreach $type (@types)
    {
      chomp($type);
      next if ($type eq "Entity Presence");
      my @sdrs = `ipmitool $cache sdr type '$type'`;
      # skip (and permanently omit) types with all 'ns' or no readings
      next if (!grep(!/\| ns  \|/ && /\|/, @sdrs));
      push(@ntypes, "$type\n");
      $bmc .= "      $type\n";
      foreach $_ (@sdrs)
      {
	my @vals = split '\|';
	next unless $#vals;
	if ($vals[0] =~ /^Temp / && $vals[1] =~ /0Ch/  && $vals[3] =~ /8.1/)
	{
	  # suppress health error for out-of-spec Nehalem memory temp sensor
	}
	elsif ($vals[2] =~ /nc/)
	{
	  $vals[0] =~ /^(.*?)\s*$/;
	  $Output{'operating'} = .97 if ($Output{'operating'} == 1) ;
	  $Output{'name'} .= "$1$vals[4] ";
	}
	elsif ($vals[2] =~ /cr/)
	{
	  $vals[0] =~ /^(.*?)\s*$/;
	  $Output{'operating'} = .3;
	  $Output{'name'} .= "$1$vals[4]! ";
	}
	elsif ($vals[2] =~ /ns/)
	{
	  next;
	}
	$bmc .= "$vals[0]|$vals[2]|$vals[4]";
      }
    }

    if (!-f $types)
    {
      if (open(T, ">$types"))
      {
	print T @ntypes;
	close(T);
      }
    }

    $bmc .= "\nRecent System Event Log messages:\n";

    my $overflow = `ipmitool sel info`;
    if ($overflow =~ /^Overflow *: true/m)
    {
      $Output{'operating'} = .96 if ($Output{'operating'} > .96) ;
      $Output{'name'} .= "SEL Overflow ";
      $bmc .= "\nSEL Overflow - logging disabled, some events may be lost!\n\n";
    }

    $Storedref->{'sel_last_id'} = "   0" if (!$Storedref->{'sel_last_id'});
    my @last10;
    my %events;
    foreach my $ev (`ipmitool $cache sel elist`)
    {
      chomp($ev);
      my @items = split(' \| ', $ev);

      splice(@items, 1, 1, "[Timestamp", "unknown]")
	if ($items[1] eq "Pre-Init Time-stamp  ");

      # Sometimes last field (Asserted/Deasserted) omitted
      # (e.g. Power Supply PS Redundancy | Redundancy Lost)
      $items[5] = "" if ($#items == 4);

      # keep all of the last 10 items
      push(@last10, "$items[1] $items[2]: $items[3] | $items[4] | $items[5]");
      shift(@last10) if (@last10 >= 10);

      # ignore any events already reported (except for SEL overflow/clear)
      if ($items[0] le $Storedref->{'sel_last_id'})
      {
	next if ($items[3] ne "Event Logging Disabled SEL");
      }
      else
      {
	$Storedref->{'sel_last_id'} = $items[0];
      }

      # update hash mapping events to last timestamp
      $events{"$items[3] | $items[4] | $items[5]"} = "$items[1] $items[2]";
    }
    my $last10time;
    foreach my $last (@last10)
    {
      $last10time = substr($last10[0], 0, 19);
      last if (substr($last10[0], 0, 1) ne "[");
    }
    foreach my $evd (sort { $events{$a} cmp $events{$b} } keys %events)
    {
      last if ($events{$evd} ge $last10time);

      $bmc .= "$events{$evd}: $evd\n";
    }
    $bmc .= join("\n", @last10) . "\n";

    # write new SEL entries to syslog, and clear if (nearly) full
    # (also done by cron.daily/checksel, which creates cron noise on warnings,
    # so we rely on running every 15 minutes (or daily, "antura" < "checksel"
    # to make sure this runs first and prevent cron noise from checksel)

    my $warning = `/usr/sbin/ipmiutil sel -w`;
    if ($warning =~ /WARNING: (free space .*?),/)
    {
      my $space = $1;
      $overflow =~ /^Percent.*: (.*)/m;
      $space = "$1 full, $space";
      $Output{'operating'} = .99 if ($Output{'operating'} == 1) ;
      $Output{'name'} .= "SEL Cleared ";
      $bmc .= "\nSystem Event Log $space";
      if (!system("/usr/sbin/ipmiutil sel -c >/dev/null"))
      {
	$bmc .= " - LOG CLEARED";
	$Storedref->{'sel_last_id'} = "   0";
      }
      $bmc .= "\n";
    }

    $bmc .= "\nField Replacable Unit Information:\n";
    $_ = `ipmitool fru`;
    $bmc .= $_;
  }

  # Abuse of the bmc test
  $bmc .= "\nSystem Identification:\n" . `getSystemId 2>/dev/null || echo`;

  if ($bmc)
  {
    $Output{'name'} .= "System" if (!$Output{'name'});
    if ($Output{'operating'} == 1)
    {
      $Output{'name'} .= "Status";
    }
    else
    {
      $Output{'name'} =~ s/^(\S+)\s*(.*) /Degraded $1 Status: $2/;
    }
    $Output{'data'} = $bmc;
  }

  1;
}

1;

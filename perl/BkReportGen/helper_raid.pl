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
# <description>Run RAID health and reporting tests.</description>

sub helper_raid($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my $raid = '';
  my %Output;

  $Output{'id'} = "raid";
  push(@$Outputarrayref, \%Output);

  if (open(X,"/proc/mdstat"))
  {
    if (grep(/active raid/,<X>))
    {
      # FC5 mdadm (v2.3) requires two 'v' options to give details with -Ds
      $raid = `mdadm -D -s -vv 2>&1`;
      $Output{'operating'} = .1 if ($raid =~ /State : (?!clean|active)/);
    }
    close(X);
  }

  if (-c '/dev/megadev0')
  {
    $_ = `megarc -ldInfo -a0 -Lall`;
    $raid .= $_;
    if (/Status: (?!OPTIMAL)/)
    {
      # <TODO>something cleverer like what we have for 3ware RAID below</TODO>
      $Output{'operating'} = .1;
      $raid .= "You may silence any beeping through the Manage link for this system\n";
    }
  }

  if (-c '/dev/megaraid_sas_ioctl_node')
  {
    $_ = `MegaCli -LDInfo -Lall -aALL`;
    $raid .= $_;
    if (/State: (?!Optimal)/)
    {
      # <TODO>something cleverer like what we have for 3ware RAID below</TODO>
      $Output{'operating'} = .1;
    }

    $raid .= "\n";
    $_ = `MegaCli -PdList -aALL`;
    $raid .= $_;
    if (/Error Count: (?!0)/)
    {
      $Output{'operating'} = .30;
    }
    if (/Predictive Failure Count: (?!0)/)
    {
      $Output{'operating'} = .40;
    }
  }

  if (-c '/dev/twa1')
  {
    $_ = `tw_cli show`;
    $raid .= $_;
    # Ctl Model Ports Drives Units NotOpt RRate VRate BBU
    /^(c\d)\s+\S+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+(\S+)/m;
    my $ctl = $1;
    my $notopt = $2;
    my $bbu = $3;
    # Battery backup unit problems (write cache automatically disabled)
    $Output{'operating'} = .8
      if ($bbu !~ /OK|Testing|Charging/i);

    # Not Optimal refers to any state except OK and VERIFYING.  Other states
    # include INITIALIZING, INIT-PAUSED, REBUILDING, REBUILD-PAUSED, DEGRADED,
    # MIGRATING, MIGRATE-PAUSED, RECOVERY, INOPERABLE, and UNKNOWN.
    # [we assign 90% health for INITIALIZING and MIGRATING; others dealt with below]
    $Output{'operating'} = .9
      if ($notopt > 0);
    $raid .= `tw_cli /$ctl show unitstatus`;
    # special case for initializing/verifying/rebuilding status
    my @raidunits = grep(/^u[0-9]/, split(/\n/, $raid));
    $Output{'operating'} = .75
      if (grep(/-PAUSED/,@raidunits));
    $Output{'operating'} = .5
      if (grep(/REBUILDING/,@raidunits));
    $Output{'operating'} = .25
      if (grep(/RECOVERY|REBUILD-PAUSED/,@raidunits));
    $Output{'operating'} = .1
      if (grep(/DEGRADED|INOPERABLE|UNKNOWN/,@raidunits));
  }

  if ($raid)
  {
    if (defined($Output{'operating'}) && $Output{'operating'} < 1)
    {
      $Output{'name'} = "Degraded RAID Status";
    }
    else
    {
      $Output{'name'} = "RAID Status";
    }
    $Output{'data'} = $raid;
  }

  1;
}

1;

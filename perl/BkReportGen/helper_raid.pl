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
# <description>Run RAID health and reporting tests.</description>

sub helper_raid($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($raid);
  my (%Output);

  $Output{'id'} = "raid";
  push(@$Outputarrayref, \%Output);

  if (open(X,"/proc/mdstat"))
  {
    if (grep(/ARRAY/,<X>))
    {
      # FC5 mdadm (v2.3) requires two 'v' options to give details with -Ds
      $raid = `mdadm -D -s -vv 2>&1`;
      $Output{'operating'} = .1 if (/State : (?!clean)/);
    }
    close(X);
  }

  if (-c '/dev/megadev0')
  {
    $_ = `megarc -ldInfo -a0 -Lall`;
    $raid .= $_;
    if (/Status: (?!OPTIMAL)/)
    {
      $Output{'operating'} = .1;
      $raid .= "You may silence any beeping through the Manage link for this system\n";
    }
  }

  if (-c '/dev/twa1')
  {
    $_ = `tw_cli show`;
    $raid .= $_;
    # Ctl Model Ports Drives Units NotOpt RRate VRate BBU
    /^(c\d)\s+\S+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+(\S+)/m;
    # Battery backup unit problems (write cache automatically disabled)
    $Output{'operating'} = .8
      if ($3 !~ /OK|Testing|Charging/i);
    $Output{'operating'} = .1
      if ($2 > 0);
    $raid .= `tw_cli /$1 show unitstatus `;
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

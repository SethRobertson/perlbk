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
# <description>Display the one, five, and fifteen minute load average,
# and additionally alert if the fifteen minute load average is over 4.
# Note the load average (w/o alerting) is displayed in top.</description>

sub helper_loadaverage($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($uptime) = `uptime`;
  my (%Output);

  if ($? != 0 || $uptime !~ /average: ([0-9\.]+)[^0-9\.]+([0-9\.]+)[^0-9\.]+([0-9\.]+)/)
  {
    return "uptime command failed: $?\n";
  }

  $Output{'name'} = "Load Average";
  $Output{'data'} = "1 Minute Load=$1  5 Minute Load=$2  15 Minute Load=$3\n";

  # This probably should be based on the number of CPUs
  if ($3 > 16)
  {
    $Output{'operating'} = .1;
    $Output{'name'} = "Tremendously High Load Average";
  }
  elsif ($3 > 8)
  {
    $Output{'operating'} = .5;
    $Output{'name'} = "Very High Load Average";
  }
  elsif ($3 > 4)
  {
    $Output{'operating'} = .75;
    $Output{'name'} = "High Load Average";
  }
  else
  {
    $Output{'operating'} = 1;
  }
  push(@$Outputarrayref, \%Output);

  1;
}

1;

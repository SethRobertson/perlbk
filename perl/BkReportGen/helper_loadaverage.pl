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
  my ($ps_cmd) = "ps axw";
  # gawk is awk on FC4. We use "gawk" so we can filter on it while
  # minimizing the changes that we're filtering out another awk processes
  # (since most people will use "awk" instead of "gawk).
  my (@ps) = `$ps_cmd -o pid,stat,uid,%cpu,vsize,priority,start,cmd | egrep -v "$ps_cmd|gawk" | gawk '\$1 == \"PID\" || \$2 ~ /[DR]/ { print }'`;
  my (%Output);
  my ($need_ps) = 0;

  if ($? != 0 || $uptime !~ /average: ([0-9\.]+)[^0-9\.]+([0-9\.]+)[^0-9\.]+([0-9\.]+)/)
  {
    return "uptime command failed: $?\n";
  }

  $Output{'data'} = "1 Minute Load=$1  5 Minute Load=$2  15 Minute Load=$3\n";

  # If you alter the defaults here you must alter the defaults in
  # admin-lib/customize-health-check.pl and awb-ids/etc/antura.conf
  my($extremely_high_load_average) = $Opt->{'extremely_high_load_average'} ||  16;
  my($very_high_load_average) = $Opt->{'very_high_load_average'} ||  8;
  my($high_load_average) = $Opt->{'high_load_average'} ||  4;

  # This probably should be based on the number of CPUs (and disks?)
  if ($3 > $extremely_high_load_average)
  {
    $Output{'operating'} = .1;
    $Output{'name'} = "EXTREMELY HIGH Load Average";
    $need_ps = 1;
  }
  elsif ($3 > $very_high_load_average)
  {
    $Output{'operating'} = .5;
    $Output{'name'} = "VERY HIGH Load Average";
    $need_ps = 1;
  }
  elsif ($3 > $high_load_average)
  {
    $Output{'operating'} = .75;
    $Output{'name'} = "HIGH Load Average";
    $need_ps = 1;
  }
  else
  {
    $Output{'operating'} = 1;
    $Output{'name'} = "Load Average";
  }

  $Output{'data'} .= "\n" . join("", @ps) if ($need_ps);
  $Output{'id'} = "loadaverage";
  push(@$Outputarrayref, \%Output);

  1;
}

1;

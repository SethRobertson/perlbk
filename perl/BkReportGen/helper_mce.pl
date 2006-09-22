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
# <description>Look for machine check exceptions (hardware problems).</description>

sub helper_mce($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($MCE_out) = "";
  my ($mcecnt_week) = 0;
  my ($mcecnt_day) = 0;
  my ($mcecnt_serious) = 0;
  my ($mytime) = time;
  my (%Output);
  my ($filename);

  $Output{'id'} = "Machine Check Exceptions";

  return(1) if (!-s "/var/log/mcelog");

  $Output{'name'} = "Machine Check Exceptions";
  $Output{'operating'} = 1;

  if (open(X, "/var/log/mcelog"))
  {
    my ($MCE,$mcecnt);
    my (@MCE) = <X>;
    $MCE = join('',@MCE);
    close(X);

    $mcecnt = grep(/^STATUS /,@MCE);
    $mcecnt_serious = grep(/uncorrected/,@MCE) + $mcecnt - grep(/ corrected /,@MCE);
    $mcecnt_week += $mcecnt;
    $mcecnt_day += $mcecnt;
    $MCE_out .= "Received before ".localtime($mytime)."\n";
    $MCE_out .= "----------------------------------------------------------------------\n";
    $MCE_out .= $MCE;
    $MCE_out .= "----------------------------------------------------------------------\n";

    if (truncate("/var/log/mcelog",0) && open(W, ">/var/log/mcelog-$mytime.$mcecnt"))
    {
      print W $MCE;
      close(W);
    }
  }


  foreach $filename (sort { $b cmp $a; } </var/log/mcelog-*.*>)
  {
    next unless ($filename =~ /-(\d+).(\d+)$/);
    my ($mcetime,$mcecnt) = ($1,$2);
    next if ($mcetime == $mytime);
    my ($MCE);
    if ($mytime - $mcetime <= 86400*7)
    {
      if (open(X, $filename))
      {
	$MCE = join('',<X>);
	close(X);
	$mcecnt_week += $mcecnt;
	$MCE_out .= "Received before ".localtime($mcetime)."\n";
	$MCE_out .= "----------------------------------------------------------------------\n";
	$MCE_out .= $MCE;
	$MCE_out .= "----------------------------------------------------------------------\n";
      }
    }

    if ($mytime - $mcetime <= 86400)
    {
      $mcecnt_day += $mcecnt;
    }
  }

  $Output{'data'} = <<EOF;

Machine check exceptions are hardware errors such as memory errors,
overheating problems, bus errors, or cache errors.  Receiving a
machine check excpetion is a sign that either your hardware is dying,
or the environment of the hardware (power, temperature, airflow) is
bad.  It may often be a good idea to reboot your system and examine
the environment; and if the problems persists, replace the hardware.
Please contact technical support for more information.

EOF

  if ($mcecnt_day >= 3)
  {
    $Output{'data'} .= <<EOF;
You have received $mcecnt_day machine check exceptions in 24 hours.

EOF
    $Output{'operating'} = .6;
  }

  if ($mcecnt_week >= 12)
  {
    $Output{'data'} .= <<EOF;
You have received $mcecnt_week machine check exceptions in 7 days.

EOF
    $Output{'operating'} = .6;
  }

  if ($mcecnt_serious)
  {
    $Output{'data'} .= <<EOF;
You have received $mcecnt_serious non-correctable machine check exception(s).
This is a sign that this system may be corrupted or otherwise not
operating properly.  Please expedite remedial efforts.  Rebooting the
system may be indicated to correct any corruption.

EOF

    $Output{'operating'} = .1;
  }

  $Output{'data'} .= $MCE_out;

  push(@$Outputarrayref, \%Output);

  1;
}

1;

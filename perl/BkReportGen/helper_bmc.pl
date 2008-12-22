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
  push(@$Outputarrayref, \%Output);

  if (-c '/dev/ipmi0')
  {
    $_ = `ipmitool chassis status`;
    $bmc .= "Chassis status:\n";
    $bmc .= $_;
    if (/(.*(Fault|Overload).*?)\s*:\s(?!false)/)
    {
      $Output{'operating'} = .3;
      $Output{'name'} = "$1";
    }

    $_ = `ipmitool sdr list`;
    $bmc .= "\nSensor status:\n";
    $bmc .= $_;
    if (!/(.*?)\s+\|.*\|\s(ok|ns)/)
    {
      $Output{'operating'} = .3;
      $Output{'name'} = "BMC $1 $2";
    }

    $bmc .= "\nField Replacable Unit Information:\n";
    $_ = `ipmitool fru`;
    $bmc .= $_;
    $bmc .= "\nLast 10 System Event Log:\n";
    $_ = `ipmitool sel list last 10`;
    $bmc .= $_;
  }

  if ($bmc)
  {
    if (!$Output{'name'})
    {
      if (defined($Output{'operating'}) && $Output{'operating'} < 1)
      {
	$Output{'name'} = "Degraded BMC Status";
      }
      else
      {
	$Output{'name'} = "BMC Status";
      }
    }
    $Output{'data'} = $bmc;
  }

  1;
}

1;

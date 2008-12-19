######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2008 The Authors. All rights reserved.
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
# <description>Run smart utilities health and reporting tests.</description>

sub helper_smart($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($smart) = "";
  my ($disk,$smartout,$exit,$name,$operating);
  my (%Output);

  $Output{'operating'} = 1.0;
  $Output{'name'} = "S.M.A.R.T. Hard Drive Information";

  open(X, "/etc/smartd.conf") || return(1);
  foreach $disk (grep(s:^(/dev\S+)(( +-d +\S+)?).*:$2 $1:, <X>))
  {
    chomp($disk);
    $disk =~ m:(/dev/\S+):;
    $smart .= $1 . "\n";
    $smartout = `smartctl -H $disk`;

    $operating = 1.0;
    $name = "S.M.A.R.T. Hard Drive Information";

    if ($? & 127)
    {
      # smartctl died with a signal; moderately serious
      $operating = .5;
      $name = "S.M.A.R.T. status request error";
      $smart .= $smartout . "\nTerminated by signal ". ($? & 127) . "\n";
    }
    else
    {
      $exit = $? >> 8;

      if ($exit & 0x08)		# bit 3 = "DISK FAILING"
      {
	$operating = .2;
	$name = "S.M.A.R.T. Hard Drive FAILING";
      }
      elsif ($exit & 0x10)	# bit 4 = "DISK OK" prefail attrs are >= thresh
      {
	$operating = .4;
	$name = "S.M.A.R.T. Hard Drive ABOUT TO FAIL";
      }
      elsif ($exit & 0x20)	# bit 5 = "DISK OK" attributes were >= thresh
      {
	$operating = .6;
	$name = "S.M.A.R.T. Hard Drive functioning POORLY";
      }
      elsif ($exit & 0x04)	# bit 2 = SMART command failure / checksum error
      {
	$operating = .8;
	$name = "S.M.A.R.T. status request error";
      }
      elsif ($exit & 0x02)	# bit 1 = device open or identification error
      {
	$operating = .9;
	$name = "S.M.A.R.T. status request error";
      }
      elsif ($exit & 0x01)	# bit 0 = command line error
      {
	$operating = .99;
	$name = "S.M.A.R.T. status request error";
      }
      elsif ($exit)		# only bits 6/7 set
      {
	$name = "S.M.A.R.T. Hard Drive Warnings";
      }
      elsif ($smartout !~ /PASSED/ && $smartout !~ /Health Status: OK/)
      {
	# While this is nominally a successful test, absence of PASSED means it
	# is probably a bogus SCSI emulation drive (like SATA) without -d option
	$operating = .99;
	$name = "S.M.A.R.T. status request result inconclusive";
      }

      $operating -= .1
	if ($exit & 0xc0);	# bits 6/7 = errors in error/self-test logs

      if ($exit & 0x40)		# bit 6 = errors in error logs
      {
	$name .= " (errors logged)";
      }

      if ($exit & 0x80)		# bit 7 = errors in self-test logs
      {
	$operating -= .1;
	$name .= " (self-test errors)";
      }

      $smart .= `smartctl -a $disk`;
    }

    if ($Output{'operating'} > $operating)
    {
      $Output{'operating'} = $operating;
      $Output{'name'} = $name;
    }
  }
  close(X);

  $Output{'data'} = $smart;
  $Output{'id'} = "smart";

  push(@$Outputarrayref, \%Output);

  1;
}

1;

######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2006-2008 The Authors. All rights reserved.
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
# <description>Look for Error Detection and Correct issues (hardware problems).</description>

sub helper_edac($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($mytime) = time;
  my (%Output);
  my ($filename);
  my (%cur);
  my (%sum);
  my ($errors);

  $Output{'id'} = "EDAC";
  $Output{'operating'} = 1;

  # Note PCI parity errors only detected if /sys/devices/system/edac/pci/check_pci_parity is non-zero
  # It is not by default

  for $filename (</sys/devices/system/edac/mc/mc*/[uc]e*_count>, </sys/devices/system/edac/pci/*count>)
  {
    if (!($filename =~ m:.*/edac/mc/(mc[^/]*)/(.*):) && !($filename =~ m:.*/edac/pci/((pci_[^/]*)):))
    {
      warn "Bad EDAC file $filename";
      next;
    }
    my ($mc,$type) = ($1,$2);

    if (!open(F,"<",$filename))
    {
      warn "Bad EDAC file $filename";
      next;
    }

    my $val = <F>;
    chomp($val);

    if (defined($Storedref->{'edac'}) && $val > $Storedref->{'edac'}->{$mc}->{$type})
    {
      my $newtype = $type;
      $newtype =~ s/_noinfo//;
      $sum{$newtype} += $val - $Storedref->{'edac'}->{$mc}->{$type};
    }
    $cur{$mc}->{$type} = $val;
    $errors += $val;
  }

  foreach my $type (keys %sum)
  {
    my $full;

    if ($type eq "ue_error")
    {
      $full = "Increasing uncorrectable memory errors (system may be corrupted)";
      $Output{'operating'} = .15 if ($Output{'operating'} > .15);
    }
    elsif ($type eq "ce_count")
    {
      $full = "Increasing correctable memory errors (system should operate properly)";
      $Output{'operating'} = .45 if ($Output{'operating'} > .45);
    }
    elsif ($type eq "pci_parity_count")
    {
      $full = "Increasing PCI bus checksum";
      $Output{'operating'} = .85 if ($Output{'operating'} > .85);
    }
    else
    {
      $full = "Other errors";
      $Output{'operating'} = .8 if ($Output{'operating'} > .8);
    }

    $Output{'data'} .= "$full: $sum{$type}\n";
  }


  if ($errors)
  {
    $Output{'name'} = "Error Detection and Correction (EDAC) Issues";
    if ($Output{'operating'} == 1)
    {
      $Output{'data'} .= "No new EDAC checks this test, but they have been observed previously.\n";
    }

    $Output{'data'} .= <<"EOF;";

Error Detection and Correction (EDAC) issues are typically caused by
memory errors and may either be correctable or uncorrectable and may
or may not be localized to a specific memory chip, though PCI parity
errors may also be detected (and are occasionally due to poor PCI card
design rather than any actual error).  Receiving an EDAC report is a
sign that either your hardware is dying, or the environment of the
hardware (power, temperature, airflow) is bad.  It is often a good
idea to reboot your system and examine the environment, filters, fans,
etc; and if the problems persists, replace the hardware.  Please
contact technical support for more information.

Detailed failure information:
EOF;

    $Output{'data'} .= `find /sys/devices/system/edac -type f | xargs egrep . 2>/dev/null`;
  }

  push(@$Outputarrayref, \%Output);

  $Storedref->{'edac'} = \%cur;

  1;
}

1;

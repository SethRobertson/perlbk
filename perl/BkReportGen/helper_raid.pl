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
      $raid = `mdadm -D -s -v 2>&1`;
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

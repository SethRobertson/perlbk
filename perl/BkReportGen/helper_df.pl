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
# <description>A module which will display the results of `df -HTl`
# and will additionally alert on any non-iso9660 filesystem which is
# over 90% utilized in either disk space or inodes.</description>

sub helper_df($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($operating) = 1;

  my ($dfkb,$dfin);
  $dfkb = `df -HTl`;
  if ($? != 0)
  {
    return "df command failed: $?\n";
  }

  $dfin = `df -HTli`;
  if ($? != 0)
  {
    return "df command failed: $?\n";
  }

  $Output{'name'} = "Disk Usage";
  $Output{'data'} = "$dfkb";
  $operating = $Output{'operating'} = 1;

  # Should we attempt to filter out crap?

  my ($line);
  foreach $line (split(/\n/,$dfkb.$dfin))
  {
    my (@fields) = split(/\s+/,$line);
    next if ($#fields < 5 || $fields[5] !~ /(\d+)\%/);
    my ($percent) = $1;

    # Under 90% utilization should be fine (though technically 91% with 20GB free is probably good as well)
    next if ($percent < 90);

    # Don't worry so much about CDs.  Yes, CDs can be mounted with other types, but not often
    next if ($fields[1] =~ /iso9660/);

    if ((100-$percent)/100 < $Output{'operating'})
    {
      $operating = $Output{'operating'} = (100-$percent)/10;
    }
    push(@warnings,$line);
  }
  push(@$Outputarrayref, \%Output);

  if ($#warnings >= 0)
  {
    my(%Warn);
    $Warn{'name'} = "DISK SPACE WARNING";
    $Warn{'data'} = join("\n",@warnings)."\n";
    $Warn{'operating'} = $operating;
    push(@$Outputarrayref, \%Warn);
  }


  1;
}

1;

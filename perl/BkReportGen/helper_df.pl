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

sub helper_df($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);

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
  $Output{'operating'} = 1;

  # Should we attempt to filter out crap?

  my ($line);
  foreach $line (split(/\n/,$dfkb.$dfin))
  {
    my (@fields) = split(/\s+/,$line);
    next if ($#fields < 5 || $fields[5] !~ /(\d+)\%/);
    my ($percent) = $1;
    next if ($percent < 90);
    if ((100-$percent)/100 < $Output{'operating'})
    {
      $Output{'operating'} = (100-$percent)/10;
    }
    push(@warnings,$line);
  }
  push(@$Outputarrayref, \%Output);

  if ($#warnings >= 0)
  {
    my(%Warn);
    $Warn{'name'} = "DISK SPACE WARNING";
    $Warn{'data'} = join("\n",@warnings)."\n";
    push(@$Outputarrayref, \%Warn);
  }


  1;
}

1;

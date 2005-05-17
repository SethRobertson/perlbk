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
# <description>A module which will include a one-time-health file</description>

sub helper_health_include($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($confidence);

  return 1 unless ($Opt->{'filename'});
  return 1 unless (open(H, $Opt->{'filename'}));

  foreach my $line (<H>)
  {
    if ($line =~ /^HEALTH=([0-9]+)/)
    {
      my ($tmp) = $1/100;
      $confidence = $confidence>$tmp?$tmp:$confidence;
    }
    push(@warnings,$line);
  }
  close(H);

  push(@$Outputarrayref, \%Output);
  $Output{'name'} = "Miscellaneous Health Warnings";
  $Output{'id'} = "health_include";

  if ($#warnings >= 0)
  {
    unlink($Opt->{'filename'});
    $Output{'data'} = join('',@warnings);
    $Output{'operating'} = defined($operating)?$operating:.9;
  }

  1;
}

1;

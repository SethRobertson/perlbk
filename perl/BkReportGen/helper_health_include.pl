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
#
# Example (typically in $ANTURA_HOME/tmp/HEALTH_INCLUDE
# HEALTH=50
# The frobnoz is overloaded
# HEALTH=0
# The biftrap is broken


sub helper_health_include($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($operating);

  return 1 unless ($Opt->{'filename'});
  return 1 unless (open(H, $Opt->{'filename'}));

  foreach my $line (<H>)
  {
    if ($line =~ s/^HEALTH=([0-9]+)\s*//)
    {
      my ($tmp) = $1/100;
      $operating = (defined($operating) && $operating<$tmp)?$operating:$tmp;
    }
    push(@warnings,$line);
  }
  close(H);

  push(@$Outputarrayref, \%Output);
  $Output{'name'} = "Miscellaneous Health Warnings";
  $Output{'id'} = "health_include";

  if ($#warnings >= 0)
  {
    unlink($Opt->{'filename'}) || push(@warning,"\nAnd could not delete $Opt->{'filename'}: $!\n");
    $Output{'data'} = join('',@warnings);
    $Output{'operating'} = defined($operating)?$operating:.9;
  }

  1;
}

1;

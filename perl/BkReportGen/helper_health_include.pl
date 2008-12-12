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
# <description>A module which will include a one-time-health file</description>
#
# Example (typically in $ANTURA_HOME/tmp/HEALTH_INCLUDE
# HEALTH=50 SUBJECT=Frobnoz alert!
# The frobnoz is overloaded
# HEALTH=0
# SUBJECT=Biftrap alert!
# The biftrap is broken


sub hhi_output($$$$$)
{
  my ($Outputarrayref, $health, $subject, $warns, $cnt) = @_;

  return unless ($warns && $#{$warns} >= 0);
  $health = 1 unless ($health);

  my (%Output);
  push(@$Outputarrayref, \%Output);
  $Output{'id'} = "health_include".($cnt?"_$cnt":"");
  $Output{'name'} = $subject || "Miscellaneous Health Warnings".($cnt?" $cnt":"");
  $Output{'operating'} = defined($health)?$health:.9;
  $Output{'data'} = join('',@{$warns});
}


sub helper_health_include($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;

  return 1 unless ($Opt->{'filename'});
  return 1 unless (open(H, $Opt->{'filename'}));

  my ($health,$subject,$cnt);
  my (@warnings);
  foreach my $line (<H>)
  {
    if ($line =~ s/^HEALTH=([0-9]+)\s*//)
    {
      hhi_output($Outputarrayref,$health,$subject,\@warnings,$cnt) if ($#warnings >= 0);
      $health = $1/100;
      undef($subject);
      undef(@warnings);
      $cnt++;
      next if length($line) < 2;
    }
    if ($line =~ s/^SUBJECT=(.*)//)
    {
      $subject = $1;
      next;
    }
    push(@warnings,$line);
  }
  hhi_output($Outputarrayref,$health,$subject,\@warnings,$cnt) if ($#warnings >= 0);
  close(H);
  unlink($Opt->{'filename'}) || push(@warning,"\nAnd could not delete $Opt->{'filename'}: $!\n");

  1;
}

1;

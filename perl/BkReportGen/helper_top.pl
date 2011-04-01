######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2011 The Authors. All rights reserved.
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
# <description>Display the results of the `top` command, usually
# looking for the top ten processes but also highlighting any
# processes of interest.</description>

sub helper_top($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);

  my ($top);
  $top = `COLUMNS=160 top -c -b -n 1`;
  if ($? != 0)
  {
    return "top command failed: $?\n";
  }

  $Output{'name'} = "Top Status";
  $Output{'id'} = "top";

  my ($num);

  if (defined($Opt) && defined($Opt->{'numberproc'}))
  {
    $num = $Opt->{'numberproc'};
  }
  else
  {
    $num = 10;
  }

  my ($line,$state);
  foreach $line (split(/\n/,$top))
  {
    if ($state)
    {
      my (@fields) = split(/\s+/,$line);
      $Output{'data'} .= "$line\n" if ($num-- > 0 || ($Opt->{'magic'} && $fields[11] =~ /$Opt->{'magic'}/));
    }
    else
    {
      next if (defined($Output{'data'}) && $line =~ /^\s*$/);
      $Output{'data'} .= "$line\n";
      $state++ if ($line =~ /PID/);
    }
  }

  push(@$Outputarrayref, \%Output);

  1;
}

1;

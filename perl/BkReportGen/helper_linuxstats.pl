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
# <description>Display certain statistics available on linux.  No errors available.</description>

sub helper_linuxstats($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($data) = scalar(`vmstat`);
  my ($Outref);
  my ($old) = $/;

  if ($? != 0)
  {
    return "vmstat command failed: $?\n";
  }

  undef($Outref);
  $Outref->{'name'} = "vmstat";
  $Outref->{'id'} = "vmstat";
  $Outref->{'data'} = $data;
  push(@$Outputarrayref, $Outref);

  undef($/);

  foreach my $f ("/proc/stat", "/proc/meminfo", "/proc/net/softnet_stat", "/proc/net/sockstat", "/proc/net/netstat", "/proc/slabinfo")
  {
    if (-f $f)
    {
      open(F,$f) || next;
      $data = <F>;
      close(F);

      undef($Outref);
      $Outref->{'name'} = "$f (for expert diagnostics)";
      $Outref->{'id'} = "$f";
      $Outref->{'data'} = $data;
      push(@$Outputarrayref, $Outref);
    }
  }

  $/ = $old;
  1;
}

1;

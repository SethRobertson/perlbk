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
# <description>A module which will display the results of `df -HTl`
# and will additionally alert on any non-iso9660 filesystem which is
# over 90% utilized in either disk space or inodes.</description>

sub helper_df($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);
  my (@warnings);
  my ($operating) = 1;

  my ($dfkb,$dfin,$pvslvs);
  $dfkb = `df -HTl`;
  if ($? != 0)
  {
    return "df command failed: $?\n";
  }

  $pvslvs = "";

  if ($dfkb =~ /Vol/)
  {
    # LVM commands will cause tons of junk errors if there happens to be a
    # CDROM loaded the first time an LVM command runs, as it puts the cdrom
    # device into its persistent_filter_cache of valid_devices, and this will
    # fail if the CDROM is ever ejected.  So we proactively prune those out.

    if (open(CACHE, "< /etc/lvm/.cache"))
    {
      my @lvmcache = <CACHE>;
      my @newlvmcache = grep(!m=/dev/cdrom=, @lvmcache);
      if ($#lvmcache != $#newlvmcache)
      {
	open(CACHE, "> /etc/lvm/.cache");
	print(CACHE join('', @newlvmcache));
      }
      close(CACHE);
    }

    # LVM commands are cranky about extra open file descriptors; appease them

    # <TRICKY bugid="8514">bash 3.1 won't close fds > 9 (e.g. 16>&-), so we
    # *move* them to fd 3 and close that - but bash gives Bad file descriptor
    # errors when moving a closed fd (closing a closed fd won't), so we must
    # check to see what's open and only attempt to close the extra fds</TRICKY>

    $pvslvs = `cd /proc/self/fd && for f in *; do case \$f in 0|1|2) :;; *)
	       test -e \$f && eval "exec 3>&\$f- 3>&-"; ((f=\$f+1)); esac; done;
	       echo; pvs; echo; lvs`;
  }

  $dfin = `df -HTli`;
  if ($? != 0)
  {
    return "df command failed: $?\n";
  }

  $Output{'name'} = "Disk Usage";
  $Output{'id'} = "df";
  $Output{'data'} = $dfkb . $pvslvs;
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

  my(%Warn);
  $Warn{'id'} = "Disk Space Warning";
  push(@$Outputarrayref, \%Warn);

  if ($#warnings >= 0)
  {
    $Warn{'name'} = "Disk Space Warning";
    $Warn{'data'} = join("\n",@warnings)."\n";
    $Warn{'operating'} = $operating;
  }


  1;
}

1;

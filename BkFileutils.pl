# $Id: BkFileutils.pl,v 1.2 2003/06/12 04:44:20 lindauer Exp $
#
# ++Copyright SYSDETECT++
#
# Copyright (c) 2001 System Detection.  All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SYSTEM DETECTION.
# The copyright notice above does not evidence any actual
# or intended publication of such source code.
# 
# Only properly authorized employees and contractors of System Detection
# are authorized to view, posses, to otherwise use this file.
# 
# System Detection
# 5 West 19th Floor 2 Suite K
# New York, NY 10011-4240
# 
# +1 212 242 2970
# <sysdetect@sysdetect.org>
# 
# --Copyright SYSDETECT--



##
# @file
# File utilties
#



use POSIX;
use Fcntl ':flock';

use constant DONT_LOCK => 1;


sub slurpfile($$);
sub writefile($$$);
sub safe_move($$);
sub update_file($$$$);



sub slurpfile($$)
{
  my($f, $flags) = @_;
  my($save,$slurp);

  if (!$f || (! -f $f))
  {
    $! = POSIX::ENOENT;
    return undef;
  }

  if (! -r $f)
  {
    $! = POSIX::EACCES
    return undef;
  }

  $save=$/; undef($/);
  if (!open(F,$f))
  {
    # <WARNING>If code is inserted here, be sure to preserve $!.</WARNING>
    $/=$save;
    return undef;
  }
  if (!($flags & DONT_LOCK) && !flock(F, LOCK_SH))
  {
    close(F);
    $/=$save;
    return undef;
  }

  $slurp=<F>;

  flock(F, LOCK_UN) unless ($flags & DONT_LOCK);
  close(F);
  $/=$save;
  $slurp;
}



sub writefile($$$)
{
  my($f,$c, $flags) = @_;

  print "Writefile called with flags **$flags**\n";

  if (!$f)
  {
    $! = POSIX::ENOENT;
    return undef;
  }

  # protect against directory traversal with crafted resource names
  if ($f =~ /\/\.\.\//)
  {
    $! = POSIX::EACCES;
    return undef;
  }

  if (!open(F,">$f"))
  {
    warn "Could not open $f\n";
    return undef;
  }

  if (!($flags & DONT_LOCK) && !flock(F, LOCK_EX))
  {
    close(F);
    return undef;
  }

  print F $c;

  flock(F, LOCK_UN) unless ($flags & DONT_LOCK);
  close(F);
}



# Move with the ability to rollback on system crash at inopportune moment.
#
# This can probably be accomplished with a simple rename() if we know 
# we're running on a journaling filesystem.
#
sub safe_move($$)
{
  my ($joburl, $queue) = @_;

  if ($joburl !~ m%.*/.*/(\d+).(\S+).jcf$%)
  {
    err_print("Malformed job url!  Cannot move to Done queue: $joburl\n");
  }
  else
  {
    my $oldqueue = $1;
    my $priority = $2;
    my $jobid = $3;
    my $backup = "$joburl.moveto.$queue";

    return 1 if ($queue eq $oldqueue);
    
    if (!writefile($backup, $tmp, 0))
    {
      err_print("Could create backup for $joburl.  Move to Done queue failed.\n");
      unlink($backup);
      return undef;
    }

    unlink($joburl);

    if (!writefile("$D{'queue'}/Done/$priority.$jobid.jcf", $tmp, 0))
    {
      err_print("Move to done queue failed: $!.\n");
      unlink($backup);
      return undef;
    }

    unlink($backup);
  }
}



# update a file, in a way that can hopefully
# recover from a crash midway through the update
sub update_file($$$$)
{
  my ($file, $find, $replace, $opts) = @_;

  $opts = '' unless $opts;

  if (!open(F, $file) || !flock(F, LOCK_EX))
  {
    return undef;
  }

  # read the file
  if (!($rc = main::slurpfile($file, DONT_LOCK)))
  {
    return undef;
  }

  # edit the file in memory
  if (!($rc =~ s/$find/$replace/))
  {
    dprint("Substitution failed.\n");
    goto ERROR;
  }

  # write out changes
  if (!main::writefile("$file.new", $rc, DONT_LOCK))
  {
    goto ERROR;
  }

  # make a backup copy of the original file
  if (!main::writefile("$file.bak", $rc, DONT_LOCK))
  {
    goto ERROR;
  }

  # delete original
  if (!unlink($file))
  {
    goto ERROR;
  }

  # rename the new file to the original filename
  if (!rename("$file.new", $file))
  {
    goto ERROR;
  }

  # delete backup
  if (!unlink("$file.bak"))
  {
    # This will cause serious problems on the next startup, but what can we do?
    err_print("Could not delete $file.bak!\n");
  }

  flock(F, LOCK_UN);

  return 1;

ERROR:
  my $save = $!;
  rollback_update($file);
  flock(F, LOCK_UN);
  $! = $save;
  return undef;
}



# return file to consistent state
sub rollback_update($)
{
  my ($file) = @_;

  my $file_exists = 1 if (-f $file);
  my $backup_exists = 1 if (-f "$file.bak");
  my $newfile_exists = 1 if (-f "$file.new");

  if ($file_exists)
  {
    # if file exists, then it's complete
    unlink("$file.new");
    unlink("$file.bak");
  }
  else
  {
    if ($backup_exists)
    {
      if (!rename("$file.bak", $file))
      {
	err_print("Rollback failed for $file: Could not restore from backup file.\n");
	return undef;
      }
    }
    else
    {
      # no original, no backup
      err_print("Rollback failed for $file: Illegal state.\n");
    }
  }
}



sub dprint
{
  print STDERR $_[0] if $main::opt_d;
}


return 1;

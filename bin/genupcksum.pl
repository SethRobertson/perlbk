#!/usr/bin/perl
#
#
#

require "getopts.pl";
require "stat.pl";
require "sys/stat.ph";

&Getopts('p:') || die;

if ($#ARGV != 0)
{
  die "Usage: $0: [-p <prune-regexp>]  <root>\n";
}

die "Cannot chdir to $ARGV[0]\n" if (!chdir($ARGV[0]));

# Start the process off
@Dirlist=($ARGV[0]);

while ($curdir = shift(@Dirlist))
{
  if (!chdir($curdir))
    {
      warn "$curdir/: Cannot chdir\n";
      next;
    }
  $curdir = "" if ($curdir eq "/");
  if (!opendir(CUR,"."))
    {
      warn "$curdir/: Cannot open directory\n";
      next;
    }

  while ($fname = readdir(CUR))
    {
      next if ($fname eq '.' || $fname eq '..');
      next if ($opt_p && "$curdir/$fname" =~ /$opt_p/);

      ($st_dev,$st_ino,$st_mode,$st_nlink,$st_uid,$st_gid,$st_rdev,$st_size,
       $st_atime,$st_mtime,$st_ctime,$st_blksize,$st_blocks) = lstat($fname);

      # If the file is a regular file
      $testmode = $st_mode & &S_IFMT;
      $testperm = $st_mode & ~(&S_IFMT);
      if (&S_IFLNK == $testmode)
	{
	  # symbolic link stuff
	  if (!($link = readlink($fname)))
	    {
	      warn "$curdir/$fname: Cannot readlink\n";
	      next;
	    }
	  print "L $curdir/$fname\001 $link\001\n";
	}
      elsif (&S_IFREG == $testmode)
	{
	  # regular file stuff
	  if (!-r _)
	    {
	      warn "$curdir/$fname: Cannot read\n";
	      next;
	    }
	  $tmp = `md5 $fname`;
	  $tmp =~ s/:(\s+[a-f0-9]+$)/\001\1/;
	  printf "F %o $st_uid $st_gid $curdir/$tmp",$testperm;
	}
      elsif (&S_IFDIR == $testmode)
	{
	  # directory stuff
	  unshift(@Dirlist,"$curdir/$fname");
	  printf "D %o $st_uid $st_gid $curdir/$fname\001\n",$testperm;
	}
      elsif (&S_IFCHR == $testmode)
	{
	  # character special
	  printf "C %o $st_uid $st_gid $curdir/$fname\001 $st_rdev\n",$testperm;
	}
      elsif (&S_IFBLK == $testmode)
	{
	  # block special
	  printf "B %o $st_uid $st_gid $curdir/$fname\001 $st_rdev\n",$testperm;
	}
      elsif (&S_IFSOCK == $testmode)
	{
	  # named socket
	  print "S $curdir/$fname\001\n";
	}
      elsif (&S_IFIFO == $testmode)
	{
	  # named pipe
	  print "P $curdir/$fname\001\n";
	}
      else
	{
	  # unknown
	  warn "$curdir/$fname: Unknown file type $st_mode\n";
	}

    }
  closedir(CUR);
}

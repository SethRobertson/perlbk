#! /usr/bin/perl -w
#
# ++Copyright BAKA++
#
# Copyright © 2007-2011 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
#

# This a program that is rarely needed but, when it is, will save your
# bacon. Given a branch name, a branch base tag, and list of files it will
# correct (re)set the branch base tag in each file. This is useful if you
# failed to set the base before branching or if you have inadvertantly
# moved the base tag and need to revert. If the named file does not contain
# the branch tag (or is not a CVS file at all), the CVS information is not
# updated.
#
# The --branch-tag and --base-tag "options" are required and are treated as
# options simply to make it easier to figure out where the list of files
# starts.
#
# ex: find -type f -print0 | xargs -0 cvs-set-branch-base.pl --branch-tag=BR --base-tag=BR_BP
#

use Getopt::Long;
use File::Basename;
use strict;

my $prog = basename($0);
my $USAGE = "Usage: $prog --branch-tag=BRANCH-TAG --base-tag=BASE-TAG files\n";
my(%OPTIONS);
Getopt::Long::Configure("bundling", "no_ignore_case", "no_auto_abbrev", "no_getopt_compat");
GetOptions(\%OPTIONS, 'branch-tag=s', 'base-tag=s', 'verbose', 'help|?') || die $USAGE;
die $USAGE if ($OPTIONS{'help'});

my $branch_tag = $OPTIONS{'branch-tag'};
my $base_tag = $OPTIONS{'base-tag'};

die $USAGE if (!$branch_tag || !$base_tag);

foreach my $file (@ARGV)
{
  open(CVS, "cvs status -v $file 2>/dev/null| ") || die "Could not execute cvs: $!\n";
  while (my $line = <CVS>)
  {
    chomp($line);
    next if ($line !~ /branch:\s/);
    $line =~ s/^\s*//;
    $line =~ s/[()]//g;
    my($tag,$rev) = (split(/\s+/, $line))[0,2];
    if ($tag eq $branch_tag)
    {
      my @rev_components = split(/\./, $rev);
      pop @rev_components if ((@rev_components % 2) == 0);
      pop @rev_components;
      my $branch_base = join('.', @rev_components);
      my $cmd = "cvs tag -F -r $branch_base $base_tag $file";
      print "$cmd\n" if ($OPTIONS{'verbose'});
      my $result = `$cmd 2>&1`;
      die "Update failed: $cmd: $result\n" if (($?>>8) != 0);
      last;
    }
  }
  close(CVS);
}

exit(0);

#!/usr/bin/perl
#
# ++Copyright BAKA++
#
# Copyright © 2003-2008 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#

foreach $file (@ARGV)
{
  open(FILE,$file) || die "Cannot open $file";
  open(OUTPUT,">$file.sort") || die "Cannot open $file.sort";
  @slurp = <FILE>;
  close(FILE);

  print OUTPUT sort diffsort @slurp;
  close(OUTPUT);
}

sub diffsort
{
  $a =~ /^[^\001]+ ([^ ]+)\001/o;
  $ta = $1;
  $b =~ /^[^\001]+ ([^ ]+)\001/o;
  $tb = $1;
  $ta cmp $tb;
}

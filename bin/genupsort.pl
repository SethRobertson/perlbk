#!/usr/bin/perl
#
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

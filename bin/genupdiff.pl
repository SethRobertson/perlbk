#!/usr/bin/perl
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

require "getopts.pl";

$PATCHDIR = "/src/oss/Packaging/HydraWEB-patches";

do Getopts('scp:') || die;

if (defined($opt_p) && !($opt_p =~ /^\d\d\d$/))
{
  die "Version number is three digits\n";
}

if ($#ARGV != 1)
{
  die "Usage: $0: [-sc] [-p version] <OLDCKSUM> <NEWCKSUM>\n";
}

$OLD = $ARGV[0];
$NEW = $ARGV[1];

if (!defined($opt_s))
{
  warn "Sorting checksum files\n";
  `genupsort.pl $OLD & genupsort.pl $NEW; wait`;
  `mv $OLD.sort $OLD; mv $NEW.sort $NEW`;
#  `sort +1 $OLD -o $OLD & sort +1 $NEW -o $NEW; wait`;
}

open(DIFF,"diff $OLD $NEW|") || die "Cannot diff\n";
@DIFFS = <DIFF>;
close(DIFF);

# Notes to self:
# > Something in NEW which is not in OLD

foreach $diff (@DIFFS)
{
  $diff =~ s: /mnt: :;		# Delete /mnt indirection
  if ($diff =~ /^</o)
    {
      # < Something in OLD which is not in NEW
      $fname = &findfname;
      next if (!DONTMUCKTEST($fname));
      $INOLD{$fname} = $diff;
      if (defined($INNEW{$fname}))
	{
	  push(@CONFLICT,$fname);
	}
      next;
    }
  if ($diff =~ /^>/o)
    {
      # > Something in NEW which is not in OLD
      $fname = &findfname;
      next if (!DONTMUCKTEST($fname));
      $INNEW{$fname} = $diff;
      if (defined($INOLD{$fname}))
	{
	  push(@CONFLICT,$fname);
	}
      next;
    }
}

#
# The fnames in @CONFLICT represent things which CHANGED between
# OLD and NEW.
#
# The fnames which appear in OLD but NOT in CHANGED are the items
# which have been deleted in NEW.
#
# The fnames which appear in NEW but NOT in CHANGED are the items
# which have been added in NEW.
#

foreach $fname (@CONFLICT)
{

  if (($type = typeof($INNEW{$fname})) ne typeof($INOLD{$fname}))
    {
      &t1print( "X Type conflict $fname\n");
      delete($INNEW{$fname});
      delete($INOLD{$fname});
      next;
    }

  if ($type =~ /[FLCBD]/)
    {
      if (&bitchange($INNEW{$fname},$INOLD{$fname}))
	{
	  movelist($fname);
	  addlist($fname);
	  &t1print("C $type $fname\n");
	  delete($INNEW{$fname});
	  delete($INOLD{$fname});
	  next;
	}
      if ($perm = (&permchange($INNEW{$fname},$INOLD{$fname})))
	{
	  &cmdlist("chmod $perm $fname");
	  &t1print("P $type $fname\n");
	}
      if ($newid = (&idchange($INNEW{$fname},$INOLD{$fname})))
	{
	  &cmdlist("chown $newid $fname");
	  &t1print("I $type $fname\n");
	}
      delete($INNEW{$fname});
      delete($INOLD{$fname});
      next;
    }

  &t1print( "X Invalid type change $type $fname\n");
  delete($INNEW{$fname});
  delete($INOLD{$fname});
}


$filter = '^$';
foreach $fname (sort keys %INOLD)
{
  next if ($fname =~ /$filter/);
  $type = typeof($INOLD{$fname});
  rmlist($fname);
  &t1print( "D $type $fname\n");
  if ($type eq 'D')
    {
      $filter .= "|^$fname";
    }
}

$filter = '^$';
foreach $fname (sort keys %INNEW)
{
  next if ($fname =~ /$filter/);
  $type = typeof($INNEW{$fname});
  addlist($fname);
  &t1print( "A $type $fname\n");
  if ($type eq 'D')
    {
      $filter .= "|^$fname";
    }
}



sub movelist
{
  push(@MOVELIST,@_);
}

sub addlist
{
  push(@ADDLIST,@_);
}

sub rmlist
{
  push(@RMLIST,@_);
}

sub cmdlist
{
  push(@CMDLIST,@_);
}

if (defined($opt_c))
{
  print join("\n",@CMDLIST),"\n";
  print "mv @MOVELIST /save\n";
  print "rm -rf @RMLIST\n";
  print "tar cf - @ADDLIST\n";
}
if (defined($opt_p))
{
  $VDIR = "$PATCHDIR/HW$opt_p-000";
  print `rm -rf $VDIR`;
  mkdir($VDIR,0777);
  open(CLIST,">$VDIR/HW$opt_p-000.CHANGELIST") || die "Cannot open changelist\n";
  print CLIST join("\n",@MOVELIST);
  print CLIST "\n";
  close(CLIST);
  open(CLIST,">$VDIR/HW$opt_p-000.COMMANDS") || die "Cannot open commands\n";
  print CLIST join("\n",@CMDLIST);
  print CLIST "\n";
  print CLIST "rm -rf @RMLIST\n";
  close(CLIST);
  open(CLIST,">$VDIR/gentar") || die "Cannot open gentar\n";
  print CLIST "tar cf - @ADDLIST | gzip\n";
  close(CLIST);
}

sub t1print
{
  print @_ if (!defined($opt_c) && !defined($opt_p));
}


sub typeof
{
  my($line) = @_;
  $line =~ s/^..//;
  my (@F) = &breakout($line);
  $F[0];
}



sub findfname
{
  my($line) = $diff;
  $line =~ s/^..//;
  my (@F) = &breakout($line);
  $F[3];
}


sub bitchange
{
  my($l1,$l2) = @_;
  $l1 =~ s/^..//;
  $l2 =~ s/^..//;
  my(@S1) = &breakout($l1);
  my(@S2) = &breakout($l2);
  $S1[4] ne $S2[4];
}


sub permchange
{
  my($l1,$l2) = @_;
  $l1 =~ s/^..//;
  $l2 =~ s/^..//;
  my(@S1) = &breakout($l1);
  my(@S2) = &breakout($l2);
  if ($S1[1] != $S2[1])
    {
      return($S1[1]);
    }
  undef;
}


sub idchange
{
  my($l1,$l2) = @_;
  $l1 =~ s/^..//;
  $l2 =~ s/^..//;
  my(@S1) = &breakout($l1);
  my(@S2) = &breakout($l2);
  if ($S1[2] != $S2[2])
    {
      return($S1[2]);
    }
  undef;
}


sub breakout
{
  my($diff) = @_;
  my($type,$perm,$id,$fname,$bits);

  if ($diff =~ /^(F) (\d+) (\d+) (\d+) (.*)\001\s+([a-f0-9]+)/)
    {
      $type = $1;
      $perm = $2;
      $id = "$3.$4";
      $fname = $5;
      $bits = $6;
    }
  elsif ($diff =~ /^(D) (\d+) (\d+) (\d+) (.*)\001/)
    {
      $type = $1;
      $perm = $2;
      $id = "$3.$4";
      $fname = $5;
      $bits = undef;
    }
  elsif ($diff =~ /^([CB]) (\d+) (\d+) (\d+) (.*)\001 ([0-9])+/)
    {
      $type = $1;
      $perm = $2;
      $id = "$3.$4";
      $fname = $5;
      $bits = $6;
    }
  elsif ($diff =~ /^([SP]) (.*)\001/)
    {
      $type = $1;
      $perm = undef;
      $id = undef;
      $fname = $2;
      $bits = undef;
    }
  elsif ($diff =~ /^(L) (.*)\001 (.*)\001/)
    {
      $type = $1;
      $perm = undef;
      $id = undef;
      $fname = $2;
      $bits = $3;
    }
  else
    {
      die "Unknown type $diff";
    }
  ($type,$perm,$id,$fname,$bits);
}


sub DONTMUCKTEST
{
  my ($fname) = @_;

  return undef if ($fname =~ m:^/etc/fstab|^/var/db:o);
  1;
}


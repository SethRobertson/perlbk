#
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
#
# File synchronized with perlbk/lib and antura-dist/lib
#
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
#
# Useful perl routines. A potpouri of functions.
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

package libbk;
use strict;

################################################################
#
#
# Normalize a path, removing '.' and '..', as well as making sure it's a
# full path. If $flag & 1 is set, then normalize_path will also attempt to
# run the path throug pawd to make sure that we get an amd path as opposed
# to a "real" path.
#
# Returns normalized path on success; undef on failure
#
sub normalize_path($;$)
{
  my($path,$flag) = @_;
  my(@components, $component, $pwd);
  my($norm_path, @norm_components);

  return(undef) if (!defined($path));

  chomp($pwd = `pwd 2>/dev/null`);

  $path = "$pwd/$path" if (substr($path, 0, 1) ne "/");

  @components = split(/\s*\/\s*/, $path);

  foreach $component (@components)
  {
    next if (($component eq ".") || ($component eq ""));

    if ($component eq "..")
    {
      pop @norm_components;
      next;
    }

    push @norm_components, $component;
  }

  $norm_path = "/" . join('/', @norm_components);

  if (defined($flag) && ($flag & 1))
  {
    chomp(my($pawd_path) = `pawd $norm_path 2>&1`);

    $norm_path = $pawd_path if (defined($pawd_path) && ($pawd_path ne ""))
  }

  return($norm_path);
}



######################################################################
#
# Varsubst
#
# This is kinda wrong, since if $foo contains "${bar}" ${bar} is not supposed
# to get expanded, but in my version here it will.
#
sub varsubst($$%)
{
  my ($prefix, $string, %subs) = @_;

  $prefix = quotemeta($prefix);

  # Simple variables of form $foo
  while ($string =~ /($prefix(\w+))/)
  {
    my $replace = ref($subs{$2}) eq 'ARRAY'?$subs{$2}->[$#{$subs{$2}}]:$subs{$2};
    my ($v) = quotemeta($1);
#    $error->dprint("Found variable $2 with <$subs{$2}> $#{$subs{$2}}\n", 4);
    my ($followedbyother) = '(?=\W|$)';
    $replace = "" unless defined($replace);
    $v = "" unless defined($v);
#    $error->dprint("Doing variables substitution with -$string- -$v- to -$replace-\n", 4);
    $string =~ s/$v$followedbyother/$replace/g;
  }

  # Simple variables of form ${foo}
  while ($string =~ /($prefix\{(\w+)\})/)
  {
    my $replace = ref($subs{$2}) eq 'ARRAY'?$subs{$2}->[$#{$subs{$2}}]:$subs{$2};
    my ($v) = quotemeta($1);
#    $error->dprint("Found variable $2 with <$subs{$2}> $#{$subs{$2}}\n", 4);
    $replace = "" unless defined($replace);
    $v = "" unless defined($v);
#    $error->dprint("Doing variables substitution with -$string- -$v- to -$replace-\n", 4);
    $string =~ s/$v/$replace/g;
  }

  # Simple array variables of form ${@foo:sep}
  while ($string =~ /($prefix\{\@(\w+)\:([^}]*)\})/)
  {
    my $replace = ref($subs{$2}) eq 'ARRAY'?$subs{$2}?join($3,@{$subs{$2}}):"":$subs{$2};
    my ($v) = quotemeta($1);
#    $error->dprint("Found variable $2 with <$subs{$2}> $#{$subs{$2}}\n", 4);
    $replace = "" unless defined($replace);
    $v = "" unless defined($v);
#    $error->dprint("Doing variables substitution with -$string- -$v- to -$replace-\n", 4);
    $string =~ s/$v/$replace/g;
  }

  # Complex variables of form ${foo:-DEFAULT} ($foo || 'DEFAULT') or ${foo:+ALTERNATE} ($foo?'DEFAULT':'')
  while ($string =~ /($prefix\{(\w+)\:([-+])([^\}]+)\})/)
  {
    my $new = ref($subs{$2}) eq 'ARRAY'?$subs{$2}->[$#{$subs{$2}}]:$subs{$2};
    my ($v) = quotemeta($1);
#    $error->dprint("Found variable $2 with <$subs{$2}> $#{$subs{$2}}\n", 4);

    $new = "" unless defined($new);
    $v = "" unless defined($v);

    $new = $4 if ($3 eq "-" && !$new);
    $new = $4 if ($3 eq "+" && $new);

#    $error->dprint("Doing variables substitution with -$string- -$v- to -$new-\n", 4);

    $string =~ s/$v/$new/g;
  }

  $string;
}



######################################################################
#
# Super-secret database password encoding
#
# Encrypt and decrypt the password using a "Vigenère cipher" This
# provides essentially zero security, but it does obscure the password
# which was the actual request.
#
sub do_vigenere($$;$)
{
  my ($encrypt,$in,$pass) = @_;
  my ($out);

  $pass = "fi5tRkH4Jh87o2Bo<--This is not providing a lot of security" unless ($pass);
  my ($plen) = length($pass);
  my (@pass) = split(//,$pass);
  my $printable = "O.Y;0>mM/f(2-qxclkAvRJ\@ PU}5WgX)#N\\!\${9B`Knh_]7<rs?+uH:'e1,6LpD~=aETd4j8wo\"\%[Gyb*FQztZC|ISV^i3\&";
  my $printablelen = length($printable);

  my $length = length($in);
  for(my $x = 0;$x < $length; $x++)
  {
    my $c = substr($in,$x,1);
    my $loc = index($printable,$c);

    # We only ``encrypt'' printable characters
    if ($loc >= 0)
    {
      if ($encrypt)
      {
	$loc += index($printable,$pass[$x%$plen]);
      }
      else
      {
	$loc -= index($printable,$pass[$x%$plen]);
      }
      $out .= substr($printable,$loc % $printablelen,1);
    }
    else
    {
      $out .= $c;
    }
  }
  $out;
}



######################################################################
#
# Quote something for the shell, as a raw argument
#
sub do_shquote($)
{
  my ($i) = @_;
  my $o;
  my $len = length($i);

  foreach(my $x=0;$x<$len;$x++)
  {
    my $c = substr($i,$x,1);
    $o .= '\\' if ($c =~ /[\\\$\`\"]/);
    $o .= $c;
  }
  '"'.$o.'"';
}


1;

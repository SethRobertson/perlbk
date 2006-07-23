# Useful perl routines. A potpouri of functions.

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


1;

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


1;

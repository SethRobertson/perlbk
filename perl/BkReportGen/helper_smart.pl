######################################################################
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
# A standard reports helper
#
# <description>Run smart utilities health and reporting tests.</description>

sub helper_smart($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my ($smart);
  my ($disk);
  my (%Output);

  open(X, "/etc/smartd.conf") || return(1);
  foreach $disk (grep(s:^(/dev\S+).*:$1:, <X>))
  {
    chomp($disk);
    `smartctl -H $disk`;

    # In theory we could decode exit code to be more precise here...
    $Output{'operating'} = .1 if ($?);

    $smart .= `smartctl -a $disk`;
  }
  close(X);

  $Output{'name'} = "S.M.A.R.T. Hard Drive Information";
  $Output{'data'} = $smart;
  $Output{'id'} = "smart";

  push(@$Outputarrayref, \%Output);

  1;
}

1;

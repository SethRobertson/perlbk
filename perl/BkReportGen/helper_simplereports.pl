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
# A standard helper to run over other standard helpers and generate a standard report
#

sub helper_simplereports($$$$$$)
{
  my ($Inforef, $StoredRef, $Outputarrayref, $CallList, $CallData, $OperatingMinRef) = @_;
  my (@Output);
  my ($call,$ret,$line);

  foreach $call (@$CallList)
  {
    $ret = eval qq^helper_$call(\$Inforef, \$StoredRef, \\\@Output, \$CallData->{"$call"});^;
    if ($@)
    {
      return "helper_$call failed with $@";
    }
    if (defined($ret) && length($ret) > 1)
    {
      return "helper_$call terminated abnormally with $ret";
    }
  }

  $$OperatingMinRef = 1;
  push(@$Outputarrayref, "".("-"x70)."\n");
  foreach $line (@Output)
  {
    # <TODO>Do something clever with HTML (think HTML::Entities)</TODO>
    # <TODO>Do more clever things with operating (Bold/blink/etc)</TODO>

    if ($line->{'operating'})
    {
      $$OperatingMinRef = $$OperatingMinRef>$line->{'operating'}?$line->{'operating'}:$$OperatingMinRef;
    }

    push(@$Outputarrayref, "$line->{'name'}:\n");
    push(@$Outputarrayref, "$line->{'data'}");
    push(@$Outputarrayref, "".("-"x70)."\n");
  }
}

1;

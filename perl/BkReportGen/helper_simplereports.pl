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
    $ret = eval qq^helper_$call(\$Inforef, \$StoredRef, \\\@Output, \$CallData->{"helper_$call"});^;
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
  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    push(@$Outputarrayref, "<table border=\"1\"><tr><td><b>Name</b></td><td><b>Results</b></td></tr>\n");
  }
  else
  {
    push(@$Outputarrayref, "".("-"x70)."\n");
  }
  foreach $line (@Output)
  {
    # <TODO>Do more clever things with operating (Bold/blink/etc)</TODO>

    if (defined($line->{'operating'}))
    {
      $$OperatingMinRef = ($$OperatingMinRef > $line->{'operating'})?$line->{'operating'}:$$OperatingMinRef;
    }

    if ($Inforef->{'OutputFormat'} eq "HTML")
    {
      # <TODO>Do something more clever with HTML (think HTML::Entities) though the <pre> is bad too</TODO>
      push(@$Outputarrayref, "<tr><td>$line->{'name'}</td><td><pre>$line->{'data'}</pre></td></tr>");
    }
    else
    {
      push(@$Outputarrayref, "$line->{'name'}:\n");
      push(@$Outputarrayref, "$line->{'data'}");
      push(@$Outputarrayref, "".("-"x70)."\n");
    }
  }
  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    push(@$Outputarrayref, "</table>\n");

    unshift(@$Outputarrayref, sprintf("<p><center>Operating at %.0f%%</center></p><br />\n",$$OperatingMinRef*100));
  }
  else
  {
    unshift(@$Outputarrayref, sprintf("                                Operating at %.0f%%\n\n",$$OperatingMinRef*100));
  }
}

1;

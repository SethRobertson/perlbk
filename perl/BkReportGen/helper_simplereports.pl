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

use constant
{
  LINELEN => 70,
};

sub helper_simplereports($$$$$$)
{
  my ($Inforef, $StoredRef, $Outputarrayref, $CallList, $CallData, $OperatingMinRef) = @_;
  my (@Output);
  my ($call,$ret,$line,$badop);
  my ($linelen) = LINELEN;

  foreach $call (@$CallList)
  {
    $ret = eval qq^helper_$call(\$Inforef, \$StoredRef, \\\@Output, \$CallData->{"helper_$call"});^;
    if ($@)
    {
      return "helper_simplereports: helper_$call failed with $@";
    }
    if (defined($ret) && length($ret) > 1)
    {
      return "helper_simplereports: helper_$call terminated abnormally with $ret";
    }
  }

  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    unshift(@$Outputarrayref, qq^<tr><td COLSPAN="2" CLASS="separator">&nbsp;</td></tr>^);
  }
  else
  {
    unshift(@$Outputarrayref, "+".("-"x($linelen-2))."+\n");
    unshift(@$Outputarrayref, "\n");
  }


  $$OperatingMinRef = 1;
  foreach $line (@Output)
  {
    next unless ($line->{'name'});

    # <TODO>Do more clever things with operating (Bold/blink/etc)</TODO>

    if (defined($line->{'operating'}))
    {
      $$OperatingMinRef = ($$OperatingMinRef > $line->{'operating'})?$line->{'operating'}:$$OperatingMinRef;
    }

    if (defined($line->{'operating'}) && $line->{'operating'} < 1.0)
    {
      $badop = 1;
      if ($Inforef->{'OutputFormat'} eq "HTML")
      {
	# <TODO>Do something more clever with HTML (think HTML::Entities) though the <pre> is bad too</TODO>
	unshift(@$Outputarrayref, qq^<tr><td bgcolor="red">$line->{'name'}</td><td><pre>$line->{'data'}</pre></td></tr>^);
      }
      else
      {
	# Prepend this failed test, so it appears at the top of the report.
	unshift(@$Outputarrayref, "+".("-"x($linelen-2))."+\n");
	unshift(@$Outputarrayref, "$line->{'data'}");
	unshift(@$Outputarrayref, "* $line->{'name'}:\n");
	unshift(@$Outputarrayref, center("* * * PROBLEM * * *") . "\n");
      }
    }
    else
    {
      if ($Inforef->{'OutputFormat'} eq "HTML")
      {
	# <TODO>Do something more clever with HTML (think HTML::Entities) though the <pre> is bad too</TODO>
	push(@$Outputarrayref, "<tr><td>$line->{'name'}</td><td><pre>$line->{'data'}</pre></td></tr>");
      }
      else
      {
	# Append results of the test.
	push(@$Outputarrayref, "$line->{'name'}:\n");
	push(@$Outputarrayref, "$line->{'data'}");
	push(@$Outputarrayref, "+".("-"x($linelen-2))."+\n");
      }
    }
  }
  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    push(@$Outputarrayref, "</table>\n");

    unshift(@$Outputarrayref, "<table border=\"1\"><tr><td><b>Name</b></td><td><b>Results</b></td></tr>\n");
    unshift(@$Outputarrayref, sprintf("<p><center>Operating at %.0f%%</center></p><br />\n",$$OperatingMinRef*100));
  }
  else
  {
    unshift(@$Outputarrayref, "+".("-"x($linelen-2))."+\n") if ($badop);
    unshift(@$Outputarrayref, sprintf("                                Operating at %.0f%%\n\n",$$OperatingMinRef*100));
  }

  $Inforef->{'LastOutputArray'} = \@Output;
  $Inforef->{'LastOperatingMin'} = int($$OperatingMinRef*100);
  1;
}



sub center($)
{
  my($string) = @_;
  my($space_over) = (LINELEN - length($string))/2;
  my($centered) = "";

  if ($space_over)
  {
    $centered .= (" "x$space_over);
  }
  $centered .= "$string";
  
  return($centered);
}

1;

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
# Sample output template to print data to a file
# Note that the "$Subject" does not appear during TEXT output.
#

# <description>Send the generated report to a file on disk.  Note text
# output does not get a "subject" line.  Usage similar to -o
# "file:/tmp/z"</description>


sub output_file($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  $output =~ s/^file://;

  return "Cannot open output file $output\n" if (!open(F,">$output"));

  my ($ret) = output_standard('F',$Inforef, $output, $subject, $data, $misc);

  close(F);

  $ret;
}

sub output_standard($$$$$;$)
{
  my ($FH, $Inforef, $output, $subject, $data, $misc) = @_;

  if ($Inforef->{'OutputFormat'} eq "HTML" && !$Inforef->{'CmdLine'}->{'HTML_Fragment'})
  {
    print $FH "<html><head><title>$subject</title></head><body>\n";
  }

  if (ref($data) eq "ARRAY")
  {
    print $FH @$data;
  }
  else
  {
    print $FH $$data;
  }


  if ($Inforef->{'OutputFormat'} eq "HTML" && !$Inforef->{'CmdLine'}->{'HTML_Fragment'})
  {
    print $FH "</body></html>\n";
  }

  1;
}

1;

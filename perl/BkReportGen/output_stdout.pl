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
# Sample output template to print data to standard out.
# Note that the "$Subject" does not appear during TEXT output.
#

sub output_stdout($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    print "<html><head><title>$subject</title></head><body><pre>\n";
  }

  if (ref($data) eq "ARRAY")
  {
    print @$data;
  }
  else
  {
    print $$data;
  }


  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    print "</body></html>\n";
  }

  1;
}

1;

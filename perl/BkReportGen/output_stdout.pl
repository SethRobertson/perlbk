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
# Sample output template to print data to standard out.
# Note that the "$Subject" does not appear during TEXT output.
#
# <description>Send the generated report to BkReportGen's standard
# output.  Note text output does not get a "subject" line.  Usage
# similar to -o stdout:</description>

sub output_stdout($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  my ($ret) = output_standard('STDOUT',$Inforef,$output, $subject, $data, $misc);

  1;
}

1;

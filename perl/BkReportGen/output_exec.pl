######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2011 The Authors. All rights reserved.
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
# <description>Send the generated report to a program as standard
# input.  Note text output does not get a "subject" line.  Usage
# similar to -o "exec:ttcp -t host"</description>

sub output_exec($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  $output =~ s/^exec://;

  return "Cannot open output pipe $output\n" if (!open(F,"|$output"));

  my ($ret) = output_standard('F',$Inforef, $output, $subject, $data, $misc);

  close(F);

  $ret;
}

1;

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
# Sample output template to print data to a file
# Note that the "$Subject" does not appear during TEXT output.
#

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

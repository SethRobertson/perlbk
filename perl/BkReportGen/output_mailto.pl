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
# Sample output template to print data to a mailer
#

# <description>Send the generated report to via electronic mail.
# Usage similar to -o "mailto:general@sysd.com"  Note email is not
# encrypted.</description>


use Mail::Mailer;

sub output_mailto($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  $output =~ s/^mailto://;

  my ($mailer) = new Mail::Mailer;
  my (%headers,$header);
  my ($charset) = $Inforef->{'CmdLine'}->{'output_mailto_charset'} || 'us-ascii';

  $headers{'To'} = $output;
  $headers{'Subject'} = $subject;

  if ($Inforef->{'OutputFormat'} eq "HTML")
  {
    $headers{'Content-Type'} = "text/html; charset=$charset";
  }
  else
  {
    $headers{'Content-Type'} = "text/plain; charset=$charset";
  }

  foreach $header (grep(/^output_mailto_header_/,keys %{$Inforef->{'CmdLine'}}))
  {
    my ($h) = $header;
    $h =~ s/output_mailto_header_//;
    $headers{$h} = $Inforef->{'CmdLine'}->{$header};
  }

  return "Cannot open output pipe $output\n" if (!$mailer->open(\%headers));

  my ($ret) = output_standard($mailer,$Inforef, $output, $subject, $data, $misc);

  close($mailer);

  $ret;
}

1;

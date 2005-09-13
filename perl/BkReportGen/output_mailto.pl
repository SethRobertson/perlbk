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
use MIME::Entity;

sub output_mailto($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  return(output_basic_mailto(@_)) if (($Inforef->{'OutputFormat'} eq "HTML") || 
				      $Inforef->{'CmdLine'}->{'NoMIME'});
  return(output_MIME_mailto(@_));
}


################################################################
#
# Create a basic one part mail. For use with HTML mail (where the 
# problems are clearly marked by a red background) and when the site
# has added NoMIME=1 to their ${mode}_health_check_args in their 
# local Baka conf file.
#
sub output_basic_mailto($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  $output =~ s/^mailto://;

  my ($mailer) = new Mail::Mailer @{$Inforef->{'mailto_args'}};
  my (%headers,$header);
  my ($charset) = $Inforef->{'CmdLine'}->{'output_mailto_charset'} || 'us-ascii';

  $headers{'To'} = $output;
  $headers{'Subject'} = $subject;

  my $from;
  if ($from = $Inforef->{'mailto_from'})
  {
    $headers{'From'} = $from;
  }

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


################################################################
#
# Create a multipart MIME message where the first part is the comprised
# of teh operational percentage and any problems which might exist and 
# the second part consists of the full report.
#
sub output_MIME_mailto($$$$;$)
{
  my($Inforef, $output, $subject, $data, $misc) = @_;
  my($sep_re) = '^\+-+\+$';
  my($ret) = 1;
  my(@data);
  my($to);
  my($top);
  my(%headers, $header);
  my($from);
  my($sendmail_args);
  my($attachment, $fh);
  my ($charset) = $Inforef->{'CmdLine'}->{'output_mailto_charset'} || 'us-ascii';

  ($headers{'To'} = $output) =~ s/^mailto://;
  $headers{'Subject'} = $subject;
  $headers{'Encoding'} = '-SUGGEST';
  $headers{'Type'} = 'multipart/mixed';

  foreach $header (grep(/^output_mailto_header_/,keys %{$Inforef->{'CmdLine'}}))
  {
    my ($h) = $header;
    $h =~ s/output_mailto_header_//;
    $headers{$h} = $Inforef->{'CmdLine'}->{$header};
  }

  if ($from = $Inforef->{'mailto_from'})
  {
    $headers{'From'} = $from;
  }

  $sendmail_args = '';
  if (@{$Inforef->{'mailto_args'}})
  {
    $sendmail_args = join(' ', @{$Inforef->{'mailto_args'}});
    if ($sendmail_args !~ /sendmail/)
    {
      $sendmail_args = '';
    }
    else
    {
      $sendmail_args =~ s/sendmail//;
    }
  }

  $top = MIME::Entity->build(%headers);
  $top->make_multipart;

  if (ref($data) eq "ARRAY")
  {
    @data = @$data;
  }
  else
  {
    @data = split(/\n/, $$data);
  }
  chomp(@data);

  my(@summary) = $data[0];

  $data[0] =~ /\s*Operating at (\d+)/;
  
  if ($1 != 100)
  {
    my($index) = 1;
    while ($data[$index] !~ /$sep_re/)
    {
      push @summary, "$data[$index++]\n";
    }

    push @summary, "$data[$index++]\n";

    while (1)
    {
      last if ($data[$index] !~ /.*PROBLEM.*/);
      while ($data[$index] !~ /$sep_re/)
      {
	push @summary, "$data[$index++]\n";
      }
      push @summary, "$data[$index++]\n";
    }
  }

  $attachment = $top->attach(
			     Type	 	=> "text/plain; charset=$charset",
			     Encoding		=> '-SUGGEST',
			     Data		=> '',
			     );
  $fh = $attachment->open("w");
  
  output_standard($fh, $Inforef, $output, $subject, \@summary, $misc);

  $fh->close;
  
  $attachment = $top->attach(
			     Type	 	=> "text/plain; charset=$charset",
			     Encoding		=> '-SUGGEST',
			     Data		=> '',
			     );
  $fh = $attachment->open("w");
  
  output_standard($fh, $Inforef, $output, $subject, $data, $misc);

  $fh->close;
  
  open (MAIL, "| sendmail $sendmail_args -t") || die "Could not spawn sendmail: $!\n";
  $top->print(\*MAIL);
  close(MAIL);
  
  $ret;
}

1;

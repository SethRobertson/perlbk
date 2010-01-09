######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2007-2010 The Authors. All rights reserved.
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


sub output_directory($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;
  my @Output;

  $output =~ s/^directory://;

  if (-d $output)
  {
    my @files = <$output/*>;
    return "Could not remove data in $output" if (@files && !unlink(@files));
    return "Could not remove $output" if (!rmdir($output));
  }
  return "Could not create $output" if (!mkdir($output));

  if (ref($data) eq "ARRAY")
  {
    @Output = @$data;
  }
  else
  {
    @Output = split(m|$/|, $$data);
  }

  while (@Output)
  {
    my $line = shift(@Output);
    chomp($line);
    last if ($line =~ /^\+\-+\+$/);
  }

  my $new_file = 1;
  while (@Output)
  {
    my $line = shift(@Output);
    chomp($line);

    if ($line =~ /^\+\-+\+$/)
    {
      close(F);
      $new_file = 1;
      next;
    }

    if ($new_file)
    {
      next if (!$line);

      my $file = $line;
      $file =~ s/\(.*\)//g;
      $file =~ s/[:\s]+$//;
      $file =~ s|[\s/]+|_|g;
      return "Could not open ${output}/${file}: $!" if !(open(F, ">> ${output}/${file}"));
      $new_file = 0;
      next;
    }

    print F $line."\n";

  }

  1;
}

1;

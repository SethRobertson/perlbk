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
# <description>Send the generated report to BkReportGen's standard
# output.  Note text output does not get a "subject" line.  Usage
# similar to -o stdout:</description>

#require "Db.pl";
use constant SQL_DONT_DIE => 1;


sub output_postgres($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;
  my ($dbchunk, $pathchunk, $dbhost, $dbport, $dbuser, $dbpass, $dbname, $table);

  die "Invalid output url $output\n" unless ($output =~ m%^postgres://([^/]*)(/.*)%);

  ($dbchunk, $pathchunk) = ($1, $2);

  if ($dbchunk)
  {
    if ($dbchunk =~ /(?:(user)(?:\:(pass))@)(host)(?:\:(port))/)
    {
      $dbhost = $3 || 'localhost';
      $dbport = $4 || 5432;
      $dbuser = $1;
      $dbpass = $2;
    }
    else
    {
      die "Cannot parse database part of $output\n";
    }
  }

  if ($pathchunk =~ m:/([^/]*)/(.*):)
  {
    $dbname = $1 || $ENV{'PGDATABASE'} || $dbuser || $ENV{'PGUSER'};
    $table = $2;
  }
  else
  {
    die "No (or improper) destination table information\n";
  }

  my (@dsn, $dbh);
  push(@dsn,"dbname=$dbname") if ($dbname);
  push(@dsn,"host=$dbhost") if ($dbhost);
  push(@dsn,"port=$dbport") if ($dbport);

  eval
  {
    # Make sure we'll die eventually if connect hangs
    local $SIG{ALRM} = sub { die "archive"; };
    alarm(60);
    $dbh = DBI->connect("dbi:Pg:".join(";",@dsn), $dbuser, $dbpass,
			{ AutoCommit => 1, Warn => 0, PrintError => 0 } )
	|| die "Database error: " . $DBI::errstr . ".\n";
  };
  alarm(0);
  if ($@)
  {
    $@ = "Timed out connecting to database." if ($@ =~ /^archive.*$/);
    die $@;
  }

  my (@operating, $operating, @name_item, $name_item, @title_item, $title_item, @result_item, $result_item);

  foreach my $line (@{$Inforef->{'LastOutputArray'}})
  {
    $line->{'name'} = "" unless $line->{'name'};
    $line->{'data'} = "" unless $line->{'data'};

    $line->{'name'} =~ s/\\/\\\\\\\\/g;
    $line->{'name'} =~ s/\n/\\\\\n/g;
    $line->{'name'} =~ s/\"/\\\\\"/g;
    $line->{'name'} =~ s/\'/\\\\\\\'/g;
    $line->{'data'} =~ s/\\/\\\\\\\\/g;
    $line->{'data'} =~ s/\n/\\\\\n/g;
    $line->{'data'} =~ s/\"/\\\\\"/g;
    $line->{'data'} =~ s/'/\\\'/g;

    push(@operating, int((defined($line->{'operating'})?$line->{'operating'}:1)*100));
    print $line->{'name'}." has null id\n" unless defined($line->{'id'});
    push(@name_item, '"'.$line->{'id'}.'"');
    push(@title_item, '"'.($line->{'name'}||"").'"');
    push(@result_item, '"'.($line->{'data'}||"").'"');
  }
  $operating = join(',',@operating);
  $name_item = join(',',@name_item);
  $title_item = join(',',@title_item);
  $result_item = join(',',@result_item);

  $title_item =~ s/\"\"/NULL/g;
  $result_item =~ s/\"\"/NULL/g;

  my ($sql) = qq(insert into $table (report_name, operating, subject, operating_item, name_item, title_item,result_item) values ('@{[$Inforef->{'Template'}]}', $Inforef->{'LastOperatingMin'}, '$subject', '{$operating}', '{$name_item}', '{$title_item}', '{$result_item}'););

  dosql($dbh, "set search_path to antura;", 0);
  dosql($dbh, $sql, 0);

  1;
}

1;

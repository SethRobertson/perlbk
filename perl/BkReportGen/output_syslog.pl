######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2010-2011 The Authors. All rights reserved.
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
# "syslog://hostname[?[facility=foo;][priority=bar;][tls]]"</description>
#
# Output format: CounterStorm Health; $sensorname; $time; %health-summary;
# [%failing-health-item, $failing-itemname;]...


use Net::Syslog;
use Sys::Hostname;


sub output_syslog($$$$;$)
{
  my ($Inforef, $output, $subject, $data, $misc) = @_;

  my ($loghost,$want_ssl,$logfacility,$loglevel);
  $loglevel = "err";
  $logfacility = "local1";
  $want_ssl = 0;

  die "Bad syslog output format\n" unless ($output =~ m!syslog://([^?]*)(?:\?(.*))?!);
  $loghost = $1;
  my $tmp = $2;
  if ($tmp)
  {
    $want_ssl = 1 if ($tmp =~ /\btls\b/);
    $loglevel = $1 if ($tmp =~ /\bpriority=(\w+)\b/);
    $logfacility = $1 if ($tmp =~ /\bfacility=(\w+)\b/);
  }

  my (@t) = gmtime;
  my ($curtime) = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",$t[5]+1900,$t[4]+1,$t[3],$t[2],$t[1],$t[0]);
  my $reportname = $Inforef->{'Template'} || "unknown";
  $reportname =~ s/;/:/g;

  my $outline = "@{[hostname]}; $curtime; $reportname; @{[$Inforef->{'LastOperatingMin'}]}%";

  if ($Inforef->{'LastOperatingMin'} != 100)
  {
    foreach my $line (sort {$a->{'operating'} <=> $b->{'operating'};} (@{$Inforef->{'LastOutputArray'}}))
    {
      next if (!defined($line->{'operating'}) || $line->{'operating'} == 1);
      my $operating = int((defined($line->{'operating'})?$line->{'operating'}:1)*100);
      my $name = $line->{'name'} || $line->{'id'};
      $name =~ s/;/,/g;
      $outline .= "; $operating%; $name";
    }
  }

  eval
  {
    my $syslog = new Net::Syslog(Name=>'CounterStorm Health', SyslogHost=>$loghost, Facility=>$logfacility, Priority=>$loglevel, SSL=>$want_ssl);
    $syslog->send($outline);
  };

  $ret;
}

1;

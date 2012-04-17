#!  /usr/bin/perl -w

use strict;
no strict "refs";
use FindBin qw($Bin);
use lib "$Bin/..";
use Baka::ScriptUtils (qw(berror bdie bruncmd bopen_log bmsg bwant_stderr bask bwarn));;
use File::Basename;
use Getopt::Long;
use Net::Pcap;
use Net::IP;


our $progname = basename($0);

my $progbase = $progname;
$progbase =~ s/\.pl$//;

my @required_args = ( "list-devs", "live", "file" );

my $USAGE = "Usage: $progname --list-devs | --live=DEV | --file=DMPFILE [--filter=FILTER] [--log-file=FILE] [--snaplen=LEN] [--[no]-promisc] [--to-ms=TIMEOUT]\n";

my(%OPTIONS);
Getopt::Long::Configure("bundling", "no_ignore_case", "no_auto_abbrev", "no_getopt_compat");
GetOptions(\%OPTIONS, 'debug|d', 'list-devs', 'live=s', 'filter=s', 'file=s', 'log-file=s', 'snaplen=i', 'verbose|v', 'promisc!', 'to-ms=i', 'help|?') || die $USAGE;
die $USAGE if ($OPTIONS{'help'});
die $USAGE if (@ARGV);

my $required_cmd_cnt = grep { my $option = $_; grep { $option eq $_; } keys %OPTIONS } @required_args;

die "$USAGE" if ($required_cmd_cnt != 1);

my $snaplen = $OPTIONS{'snaplen'} // 1024;
my $promisc = $OPTIONS{'promisc'};
my $to_ms = $OPTIONS{'to-ms'} // 0;

my $log_file = $OPTIONS{'log-file'} || "/tmp/${progbase}.$ENV{USER}";
my $log = bopen_log($log_file);
bwant_stderr(1);

my $pcap;
my $pcap_err;
if ($OPTIONS{'list-devs'})
{
  my %devinfo;
  my @devs = Net::Pcap::pcap_findalldevs(\%devinfo, \$pcap_err);

  bdie("Could not determine the list of devices: $pcap_err", $log) if ($pcap_err);

  foreach my $dev (@devs)
  {
    if (!$OPTIONS{'verbose'})
    {
      print "$dev\n";
    }
    else
    {
      print "$dev: $devinfo{$dev}\n";
    }
  }
  exit(0);
}
elsif ($OPTIONS{'live'})
{
  my $dev = $OPTIONS{'live'};
  
  bdie("Could not open $dev: $pcap_err", $log) if (!($pcap = Net::Pcap::pcap_open_live($dev, $snaplen, $promisc, $to_ms, \$pcap_err)));
}
else
{
  my $savefile = $OPTIONS{'file'};
  bdie("Could not open savefile: $savefile: $pcap_err", $log) if (!($pcap = Net::Pcap::pcap_open_offline($savefile, \$pcap_err)));
}

my %pcap_header;
while (my $pkt = pcap_next($pcap, \%pcap_header))
{
  
}

exit(0);

sub END
{
  Net::Pcap::close($pcap) if (defined($pcap));
}

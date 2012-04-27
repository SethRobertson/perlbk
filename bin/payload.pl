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
use Socket;
use NetPacket qw(htonl htons);
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;
use NetPacket::UDP;
use FileHandle;
use Data::Dumper;

sub make_association($$$$$ );
sub destroy_assoc($$ );
sub get_direction($$$ );

use constant
{
  ETHERTYPE_IP		=> 2048, 	#net/ethernet.h
  IPPROTO_TCP		=> 6,
  IPPROTO_UDP		=> 17,
  TIMEOUT_2MSL		=> 240.0, # The comparison is with a floating point number.
};

use constant
{
  DIRECTION_FROM_SOURCE	=> 0,
  DIRECTION_TO_SOURCE	=> 1,
};


our $progname = basename($0);

my $progbase = $progname;
$progbase =~ s/\.pl$//;

my @required_args = ( "list-devs", "live", "file" );

my $USAGE = "Usage: $progname --list-devs | --live=DEV | --file=DMPFILE [--filter=FILTER] [--log-file=FILE] [--netmask=NETMASK] [--[no-]optimize] [--snaplen=LEN] [--[no]-promisc] [--to-ms=TIMEOUT] [--bidir!] [--dir=DIRECTORY] [--[no-]permit-misordered]\n";

my(%OPTIONS);
Getopt::Long::Configure("bundling", "no_ignore_case", "no_auto_abbrev", "no_getopt_compat");
GetOptions(\%OPTIONS, 'debug|d', 'list-devs', 'live=s', 'filter=s', 'file=s', 'log-file=s', 'snaplen=i', 'verbose|v', 'promisc!', 'netmask=s', 'optimize!', 'to-ms=i', 'permit-misordered!', 'bidir!', 'help|?') || die $USAGE;
die $USAGE if ($OPTIONS{'help'});
die $USAGE if (@ARGV);

my $required_cmd_cnt = grep { my $option = $_; grep { $option eq $_; } keys %OPTIONS } @required_args;

die "$USAGE" if ($required_cmd_cnt != 1);

my $snaplen = $OPTIONS{'snaplen'} // 1024;
my $promisc = $OPTIONS{'promisc'} // 1;
my $to_ms = $OPTIONS{'to-ms'} // 0;
my $filter_str = $OPTIONS{'filter'} // "";
my $netmask_str = $OPTIONS{'netmask'} // "0.0.0.0";
my $optimize = $OPTIONS{'optimize'} // 0;
my $bidir = $OPTIONS{'bidir'} // 1;
my $dir = $OPTIONS{'dir'} // "/tmp/payload.d";
my $permit_misordered = $OPTIONS{'permit_misordered'} // 1;

my $log_file = $OPTIONS{'log-file'} // "/tmp/${progbase}.$ENV{USER}";
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

if ($filter_str)
{
  my $filter;
  my $netmask = inet_aton($netmask_str);
  bdie("Could not compile filter: " . Net::Pcap::pca_geterr($pcap), $log) if (Net::Pcap::pcap_filter($pcap, \$filter, $filter_str, $optimize, $netmask) < 0);
  bdie("Could not set the filter: " . Net::Pcap::pca_geterr($pcap), $log) if (Net::Pcap::set_filter($pcap, $filter) < 0);
  Net::Pcap::pcap_freecode($filter);
}

bdie("Could not create $dir", $log) if (bruncmd("mkdir -p $dir", $log) != 0);

my %pcap_header;
my $assoc_info = {};
my ($pkt_cnt, $ip_pkt_cnt, $last_pkt_time, $misordered_cnt) = (0, 0, 0.0, 0);
while (my $pkt = Net::Pcap::pcap_next($pcap, \%pcap_header))
{
  $pkt_cnt++;

  # Get paket time
  my $pkt_time = $pcap_header{'tv_sec'} + $pcap_header{'tv_usec'} / 1000.0;

  # Obtain packet.
  my $eth_obj = NetPacket::Ethernet->decode($pkt);

  # Check and update packet time (before we do any kind of filtering).
  if ($pkt_time < $last_pkt_time)
  {
    bwarn("Out of order packet! Results may be unpredictable", $log) if (!$misordered_cnt);
    $misordered_cnt++;
    next if (!$permit_misordered);
  }
  else
  {
    # NB: We only *advance* the packet time. Time stamps on misordered packets are ignored.
    $last_pkt_time = $pkt_time;
  }

  # Skip non-IP packet.
  next if (($eth_obj->{'type'}&0xffff) != ETHERTYPE_IP);

  my $ip_pkt = $eth_obj->{'data'};
  $ip_pkt_cnt++;

  my $ip_obj = NetPacket::IP->decode($ip_pkt);

  my($src_ip, $dst_ip, $proto); # "dest"? Sheesh..
  if ($ip_obj->{'foffset'} == 0)
  {
    $src_ip = $ip_obj->{'src_ip'};
    $dst_ip = $ip_obj->{'dest_ip'};
    $proto = $ip_obj->{'proto'};
  }
  else
  {
    # <TODO> Handle frangments. Uggh.. </TODO>
    bwarn("Fragments not currently handled!", $log);
    next;
  }

  next if (($proto != IPPROTO_TCP) &&  ($proto != IPPROTO_UDP));

  my ($tcp_obj, $udp_obj, $src_port, $dst_port, $data);
  # Decode transport layer and set ports and data.
  if ($proto == IPPROTO_TCP)
  {
    $tcp_obj = NetPacket::TCP->decode($ip_obj->{'data'});
    $src_port = $tcp_obj->{'src_port'};
    $dst_port = $tcp_obj->{'dest_port'};
    $data = $tcp_obj->{'data'};
  }
  else
  {
    $udp_obj = NetPacket::TCP->decode($ip_obj->{'data'});
    $src_port = $udp_obj->{'src_port'};
    $dst_port = $udp_obj->{'dest_port'};
    $data = $udp_obj->{'data'};
  }

  my $assoc = make_association($src_ip, $dst_ip, $proto, $src_port, $dst_port);

  # Set the first_from immediately.
  my $first_from;
  if (!defined($assoc_info->{$assoc}))
  {
    $assoc_info->{$assoc}->{'first_from'} = $first_from = $src_ip;
    $assoc_info->{$assoc}->{'proto'} = $proto;
  }
  else
  {
    $first_from = $assoc_info->{$assoc}->{'first_from'};
  }

  # Update association time.
  $assoc_info->{$assoc}->{'last_pkt_time'} = $pkt_time;
  
  # Set the direction packet.
  my $direction = get_direction($assoc_info, $assoc, $src_ip);

  # If this a TCP segment then check to see if the FIN is set so we can track close conditions.
  if (($proto == IPPROTO_TCP) && ($tcp_obj->{'flags'} & FIN))
  {
    $assoc_info->{$assoc}->{'FIN'}->{$src_port} = 1;
  }

  my $fh;
  if ($data)
  {
    if (!defined($fh = $assoc->{$assoc}->{$direction}->{'fh'}))
    {
      my $filename;
      if (!$OPTIONS{'bidir'} || ($direction eq DIRECTION_FROM_SOURCE))
      {
	$filename = $assoc;
      }
      else
      {
	$filename = "${proto}-${dst_ip}:${dst_port}:${src_ip}:${src_port}"
      }

      bdie("Could not open $filename for writing: $!", $log) if (!($fh = FileHandle->new(">> $filename")));
      $assoc->{$assoc}->{$src_port}->{$direction} = $fh;
      if ($bidir)
      {
	my $other_direction = !$direction;
	$assoc->{$assoc}->{$dst_port}->{$other_direction} = $fh;
      }
    }
    
    if ($bidir)
    {
      if ($direction eq DIRECTION_FROM_SOURCE)
      {
	print $fh "\n>>>>>>\n";
      }
      else
      {
	print $fh "\n<<<<<<\n";
      }
    }
    print $fh $data;
  }

  # Don't save UDP "associations" as there really is no such thing (so,
  # yes, UDP's cause the data file to open close each time;
  destroy_assoc($assoc_info, {$assoc}) if ($proto == IPPROTO_UDP);

  # Scan the TCP associattions for those that have timed out. NB: $assoc is
  # *reused* here, so this must always be the last thing in the
  # function. Too bad we don't have try/finally.
  foreach $assoc (keys(%{$assoc_info}))
  {
    next if ($assoc_info->{$assoc}->{'proto'} != IPPROTO_TCP); # This should always be true of course.
    destroy_assoc($assoc_info, $assoc) if (($assoc_info->{$assoc}->{'last_pkt_time'} - $pkt_time) >= TIMEOUT_2MSL);
  }
}

exit(0);

sub END
{
  Net::Pcap::pcap_close($pcap) if (defined($pcap));
}


sub make_association($$$$$ )
{
  my ($src_ip, $dst_ip, $proto, $src_port, $dst_port) = @_;

  my $sip = htonl(inet_aton($src_ip));
  my $dip = htonl(inet_aton($dst_ip));
  my $sport = htons($src_port);
  my $dport = htons($dst_port);

  return((($sip < $dip) || ($sport < $dport))?"${proto}-${src_ip}:${src_port}-${dst_ip}:${dst_port}":"${proto}-${dst_ip}:${dst_port}-${src_ip}:${src_port}");
}


sub destroy_assoc($$ )
{
  my($assoc_info, $assoc) = @_;
  my $src_fh = $assoc_info->{$assoc}->{DIRECTION_FROM_SOURCE}->{'fh'};
  my $dst_fh = $assoc_info->{$assoc}->{DIRECTION_TO_SOURCE}->{'fh'};

  if (defined($src_fh))
  {
    if (defined($dst_fh) && ($src_fh != $dst_fh))
    {
      $dst_fh->close();
      delete($assoc_info->{$assoc}->{$dst_fh}); # Belt/suspenders
    }
    
    $src_fh->close();
    delete($assoc_info->{$assoc}->{$src_fh}); # Belt/suspenders
  }

  delete($assoc_info->{$assoc});
  return(0);
}

sub get_direction($$$ )
{
  my($assoc_info, $assoc, $src) = @_;

  return(($assoc_info->{$assoc}->{'first_from'} eq $src)?@{[DIRECTION_FROM_SOURCE]}:@{[DIRECTION_TO_SOURCE]});
}

package BkError;
{
  my $debug;



  sub new($$)
  {
    ($this, $debug) = @_;
    my $self = {};
    bless $self;
    print STDERR "Debugging on ($debug).\n" if ($debug);
    $debug = 0 unless ($debug);
    return $self;
  }



  ###################################
  # msg - debug message to print
  # level - Minimum debug level to print message (default 1)
  #
  sub dprint($$)
  {
    my ($this, $msg, $level) = @_;

    $level = 1 if (!defined($level));

    print STDERR $_[1] if ($debug >= $level);
  }



  sub err_print($)
  {
    print STDERR $_[1];
  }
}

return 1;

package BkError;
{
  my $debug;


  sub new($)
  {
    ($this, $debug) = @_;
    my $self = {};
    bless $self;
    print STDERR "Debugging on.\n" if ($debug);
    return $self;
  }


  sub dprint($)
  {
    print STDERR $_[1] if $debug;
  }



  sub err_print($)
  {
    print STDERR $_[1];
  }
}

return 1;

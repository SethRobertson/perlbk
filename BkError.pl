package BkError;
{
  my $debug;


  sub new($)
  {
    my ($opt_d) = @_;
    my $self = {};
    bless $self;
    $debug = $opt_d;
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

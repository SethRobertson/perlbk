use Log::Dispatch;
use Log::Dispatch::Syslog;
use Log::Dispatch::Screen;

package BkError;
use strict;
{
  sub new()
  {
    my ($class, $ident, $print_level, $log_level, $log_method, $debug) = @_;

    die "Internal error: missing required parameters for BkError.\n" unless ($ident && $print_level && $log_level);

    my $self = {};
    bless $self;

    $self->{'debug'} = $debug || 0;

    if ($log_method)
    {
      if (($log_method ne 'inet') && ($log_method ne 'unix'))
      {
	die "Invalid syslog method ($log_method).  Must be 'inet' or 'unix'.\n";
      }
    }
    else
    {
      $log_method = 'inet';
    }
    
    die "Invalid print level ($print_level).\n" if !Log::Dispatch->level_is_valid($print_level);
    die "Invalid log level ($log_level).\n" if !Log::Dispatch->level_is_valid($log_level);

    my $logger = Log::Dispatch->new();
    
    $logger->add( Log::Dispatch::Syslog->new( name => 'syslogger',
					      min_level => $log_level,
					      ident => $ident,
					      logopt => 'pid',
					      facility => 'user',
					      socket => $log_method ));
    
    $logger->add( Log::Dispatch::Screen->new( name => 'screenlogger',
					      min_level => $print_level ));
    
    $self->{'logger'} = $logger;

    return $self;
  }



  ###################################
  # msg - debug message to print
  # level - Minimum debug level to print message (default 1)
  #
  sub dprint($$$)
  {
    my ($self, $msg, $level) = @_;
    my ($errlevel);
    my ($debug) = $self->{'debug'};

    $level = 1 unless ($level);

    if ($debug >= $level)
    {
      err_print($self, $msg, 'debug');
    }
  }



  sub err_print($$$)
  {
    my ($self, $message, $level) = @_;
    my $print_level = $self->{'print_level'};
    my $logger = $self->{'logger'};

    $level = 'err' unless ($level);

    if (!Log::Dispatch->level_is_valid($level))
    {
      $logger->log(level => 'err', message => "Internal error: invalid log level ($level).\n");
      $level = 'err';
    }

    $logger->log(level => $level, message => $message);
  }

    
}

return 1;

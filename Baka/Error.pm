# $Id: Error.pm,v 1.12 2005/05/17 17:34:16 lindauer Exp $
#
# ++Copyright LIBBK++
# 
# Copyright (c) 2003 The Authors. All rights reserved.
# 
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
# 
# Mail <projectbaka\@baka.org> for further information
# 
# --Copyright LIBBK--
#



##
# @file
# Error logger.
#



use Log::Dispatch;
use Log::Dispatch::Syslog;
use Log::Dispatch::Screen;
use FileHandle;

package Baka::Error;
require Exporter;
@ISA = qw (Exporter);
@EXPORT_OK = qw(err_print dprint);
$VERSION = 1.00;
use strict;
{
  ##
  # Constructor. 
  # Valid log levels are emerg, alert, crit, err,
  # warning, notice, info, and debug.
  #
  # @param ident identifier for syslog output (program name)
  # @param print_level threshold for printing an error
  # @param log_level threshold for logging an error
  # @param log_method inet (default) or unix
  # @param want_pid add pid to all messages
  # @param debug debugging verbosity (larger means more messages)
  #
  sub new()
  {
    my ($class, $ident, $print_level, $log_level, $log_method, $want_pid, $debug) = @_;

    die "Internal error: missing required parameters for Baka::Error.\n" unless ($ident && $print_level && $log_level);

    my $self = {};
    bless $self;

    $self->{'debug'} = $debug || 0;
    
    $self->{'want_pid'} = $want_pid;

    if ($log_method)
    {
      if (($log_method ne 'inet') && ($log_method ne 'unix'))
      {
	die "Invalid syslog method ($log_method).  Must be 'inet' or 'unix'.\n";
      }
    }
    else
    {
      $log_method = 'unix';
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
   
    if ((-t STDERR) || $debug)
    {
      $logger->add( Log::Dispatch::Screen->new( name => 'screenlogger',
						min_level => $print_level,
						stderr => 1 ));
    }
   
    $self->{'logger'} = $logger;

    return $self;
  }


  ##
  # Toggle runtime debugging to file.
  #
  # @param enable 1 to enable, 0 to disable
  # @param filename log file
  #
  sub toggle_dynamic_debug($$$)
  {
    my ($self, $enable, $filename) = @_;

    if ($enable)
    {
      if (!$self->{'dyn_debug_file'})
      {
	$self->{'dyn_debug_file'} = FileHandle->new;
	if (!$self->{'dyn_debug_file'}->open(">$filename"))
	{
	  err_print($self, "Dynamic debug open failed: $!.\n");
	  $self->{'dyn_debug_file'} = undef;
	}
      }
    }
    else
    {
      if ($self->{'dyn_debug_file'})
      {
	$self->{'dyn_debug_file'}->close();
	$self->{'dyn_debug_file'} = undef;
      }
    }
  }


  ##
  # Print a debugging message.
  #
  # @param msg debug message to print
  # @param level Minimum debug level to print message (default 1)
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
    elsif ($self->{'dyn_debug_file'})
    {
      my $fh = $self->{'dyn_debug_file'};
      print $fh "[$$] $msg";
    }
  }



  ##
  # Print/log an error message
  #
  # @param message message to print
  # @param level level at which to print/log the message (see constructor comment).
  #
  sub err_print($$$)
  {
    my ($self, $message, $level) = @_;
    my $print_level = $self->{'print_level'};
    my $logger = $self->{'logger'};
    my $want_pid = $self->{'want_pid'};

    $level = 'err' unless ($level);

    if (!Log::Dispatch->level_is_valid($level))
    {
      $logger->log(level => 'err', message => "Internal error: invalid log level ($level).\n");
      $level = 'err';
    }

    $message = "[$$] $message" if $want_pid; 

    $logger->log(level => $level, message => $message);

    if ($self->{'dyn_debug_file'})
    {
      my $fh = $self->{'dyn_debug_file'};
      print $fh $message;
    }
  }


  ##
  # Print a message to be included in the next health check message
  #
  # @param message message to print
  # @param pct health check percent, default 90%, lowest wins
  # @return <i>1</i> on success
  # @return <i>undef</i> on failure
  #
  sub write_health($;$)
  {
    my ($message, $pct) = @_;
    my ($fh);
    my $health_check_file = $ENV{'ANTURA_HOME'} . "/tmp/HEALTH_INCLUDE";

    $fh = new FileHandle;
    if (!($fh->open(">> $health_check_file")))
    {
      return undef;
    }

    print $fh "\n";

    if (defined($pct) && ($pct >=0) && ($pct <= 99))
    {
      print $fh "HEALTH=$pct\n";
    }

    print $fh "$message\n";

    $fh->close();
    return 0;
  }
}

return 1;

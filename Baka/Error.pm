# $Id: Error.pm,v 1.4 2003/06/17 06:20:26 seth Exp $
#
# ++Copyright SYSDETECT++
#
# Copyright (c) 2003 System Detection.  All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SYSTEM DETECTION.
# The copyright notice above does not evidence any actual
# or intended publication of such source code.
#
# Only properly authorized employees and contractors of System Detection
# are authorized to view, possess, to otherwise use this file.
#
# System Detection
# 5 West 19th Street Floor 2K
# New York, NY 10011-4240
#
# +1 212 206 1900
# <support@sysd.com>
#
# --Copyright SYSDETECT--



##
# @file
# Error logger.
#



use Log::Dispatch;
use Log::Dispatch::Syslog;
use Log::Dispatch::Screen;

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
  # @param debug debugging verbosity (larger means more messages)
  #
  sub new()
  {
    my ($class, $ident, $print_level, $log_level, $log_method, $debug) = @_;

    die "Internal error: missing required parameters for Baka::Error.\n" unless ($ident && $print_level && $log_level);

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

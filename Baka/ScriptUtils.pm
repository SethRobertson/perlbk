# -*- perl -*-
# $Id: ScriptUtils.pm,v 1.6 2006/04/13 15:07:03 jtt Exp $
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
# Random utilities useful for dealing with scripts.
#

package Baka::ScriptUtils;
use Switch;
use IO::File;
use Baka::Error;
use POSIX qw(isatty);
use Exporter 'import';
@EXPORT_OK = qw (berror bmsg bdebug bdie bruncmd bopen_log);


################################################################
#
# Print an error message to an optional log or Baka::Error stream
#
sub berror($$ )
{
  my($msg, $log) = @_;

  # Make sure the message a separator at the end.
  chomp($msg);
  $msg .= $/;  

  if (ref($log) eq "Baka::Error")
  {
    $log->err_print($msg);
  }
  else
  {
    print $log "$msg";
  }

  return;
}



################################################################
#
# Print a message to an optional log or Baka::Error stream (at debug level)
#
sub bdebug($$ )
{
  my($msg, $log) = @_;

  # Make sure the message a separator at the end.
  chomp($msg);
  $msg .= $/;  

  if (ref($log) eq "Baka::Error")
  {
    $log->dprint($msg);
  }
  else
  {
    print $log "$msg";
  }

  return;
}



################################################################
#
# Print a message to an optional log or Baka::Error stream (at info level)
#
sub bmsg($$ )
{
  my($msg, $log) = @_;

  # Make sure the message a separator at the end.
  chomp($msg);
  $msg .= $/;  

  if (ref($log) eq "Baka::Error")
  {
    $log->dprint($msg, 'info');
  }
  else
  {
    print $log "$msg";
  }

  return;
}



################################################################
#
# Die with an optional message and error code
#
sub bdie($;$$ )
{
  my($msg, $log, $ecode) = @_;

  $ecode = 1 if (!defined($ecode));
  berror($msg, $log);

  if (isatty(fileno(STDERR)))
  {
    # Make sure the message a separator at the end.
    chomp($msg);
    $msg .= $/;  
    print STDERR "$msg";
  }
  exit($ecode);
}



################################################################
#
# Run a shell command. Optionally collect output and return code.
# May optionally ignore non-success return codes.
# May optinoally set the value of success
#
sub bruncmd($;$$$$$$ )
{
  my($cmd, $log, $output_r, $retcode_r, $ignore_error_code, $success_code, $ignore_output) = @_;

  if ($output_r)
  {
    switch (ref($output_r))
    {
      case "ARRAY" { @$output_r = (); }
      case "SCALAR" { $$output_r = ""; }
    }
  }

  $success_code = 0 if (!defined($success_code));

  print $log "Running cmd: $cmd: ";
    
  chomp(my @lines = `$cmd 2>/dev/stdout`);
  
  my $sig = $?&0x7f;
  my $ret = ($?>>8)&0xff;

  print $log "$ret";
  print $log " [signal: $sig]" if ($sig);
  print $log " (ignored)" if ($ignore_error_code && ($ret != $success_code));
  print $log "\n";

  if (@lines)
  {
    my $output_str = "" . join("$/", @lines) . "$/";

    if (!$ignore_output)
    {
      print $log "------------------------------------------------------------\n";
      print $log "$output_str";
      print $log "------------------------------------------------------------\n";
    }
    
    if ($output_r)
    {
      switch (ref($output_r))
      {
	case "ARRAY" { @$output_r = @lines; }
	case "SCALAR" { $$output_r = $output_str; }
      }
    }
  }
  
  $$retcode_r = $ret if ($retcode_r);
  return($ret);
}



################################################################
#
# Open a log file of the type used by these routines.
#
sub bopen_log($;$$ )
{
  my($filename, $append, $error, $no_autoflush) = @_;
  my $write_open_type;
  
  my $log = new IO::File;

  return(undef) if (!$log);

  if ($append)
  {
    $write_open_type = ">>";
  }
  else
  {
    $write_open_type = ">";
  }

  if (!($log->open("$write_open_type $filename")))
  {
    $error->err_print("Could not open $filename for writing: $!\n") if ($error);
    $log->close;
    return(undef);
  }

  $log->autoflush(1) unless ($no_autoflush);
  return($log);
}


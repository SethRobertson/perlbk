# -*- perl -*-
# $Id: ScriptUtils.pm,v 1.7 2006/08/18 21:58:08 jtt Exp $
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
@EXPORT_OK = qw (berror bmsg bdebug bdie bruncmd bopen_log bwant_stderr);

my $want_stderr = 0;

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
sub bdie($$;$ )
{
  my($msg, $log, $ecode) = @_;

  $ecode = 1 if (!defined($ecode));
  berror($msg, $log);

  if (isatty(fileno(STDERR)) || $want_stderr)
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
# May optionally set the value of success
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
    
  # If the caller is catching SIGCHLD, he probably doesn't want it caught for this, so 
  # reset it across the backtick call.
  my $old_chld = $SIG{'CHLD'};
  $SIG{'CHLD'} = 'DEFAULT';
  chomp(my @lines = `$cmd 2>/dev/stdout`);
  $SIG{'CHLD'} = $old_chld;
  
  my $exitcode = ($?&0xffff);
  my $sig = $exitcode&0x7f;
  my $ret = ($exitcode>>8)&0xff;

  print $log "$ret";
  print $log " [signal: $sig]" if ($sig);
  print $log " (ignored)" if ($ignore_error_code && ($ret != $success_code));
  print $log "\n";

  print $log "------------------------------------------------------------\n";

  if (@lines)
  {
    my $output_str = "" . join("$/", @lines) . "$/";

    if (!$ignore_output)
    {
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
sub bopen_log($;$$$ )
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


################################################################
#
# Obtain or set the value of want_stderr
#
sub bwant_stderr(;$)
{
  my($preference) = @_;

  return $want_stderr if (!defined($preference));
  
  $want_stderr = $preference;
  return;
}

1;

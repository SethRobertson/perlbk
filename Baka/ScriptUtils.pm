# -*- perl -*-
# $Id: ScriptUtils.pm,v 1.1 2006/04/10 20:03:22 jtt Exp $
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
use Exporter 'import';
@EXPORT_OK = qw (berror bdie bruncmd bopen_log);


################################################################
#
# Print an error message to an optional log or error source.
#
sub berror($;$$ )
{
  my($msg, $log, $error) = @_;

  # Make sure the message a separator at the end.
  chomp($msg);
  $msg .= $/;  
  
  $error->err_print("$msg") if ($error);
  print $log "$msg" if ($log);
  
  return;
}



################################################################
#
# Die with an optional message and error code
#
sub bdie($;$$$ )
{
  my($msg, $log, $error, $ecode) = @_;

  $ecode = 1 if (!defined($ecode));
  berror($msg, $error, $log);
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

  $success_code = 0 if (!defined($success_code));

  print $log "Running cmd: $cmd: ";
    
  my @lines = `$cmd 2>/dev/stdout`;
  
  my $sig = $?&0x7f;
  my $ret = ($?>>8)&0xff;

  print $log "$ret";
  print $log " [signal: $sig]" if ($sig);
  print $log " (ignored)" if ($ignore_error_code && ($ret != $success_code));

  my $output_str = "" . join("$/", @lines) . "$/";

  if (!$ignore_output)
  {
    print $log "------------------------------------------------------------";
    print $log "$output_str";
    print $log "------------------------------------------------------------";
  }
  
  if ($output_r)
  {
    switch (ref($output_r))
    {
      case "ARRAY" { @$output_r = @lines; }
      case "SCALAR" { $$output_r = $output_str; }
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


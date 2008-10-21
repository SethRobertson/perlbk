# -*- perl -*-
#
#
# ++Copyright BAKA++
#
# Copyright © 2006-2008 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#

=head1 NAME

Baka::ScriptUtils - Helful routines for writing Baka Perl scripts

=head1 SYNOPSIS

=over 6

  use Baka::ScriptUtils qw (berror bmsg bdebug bdie bruncmd bopen_log bwant_stderr bask)

  bopen_log($filename);
  berror($msg, $log, $no_break);
  bdebug($msg, $log, $no_break);
  bmsg($msg, $log, $no_break);
  bdie($msg, $log, $exitcode);
  bask($msg, $reply_r, $log, $pattern);

  bruncmd($cmd, $log, \@output, \$retcode, $ignore_error_code, $success_code, $ignore_output);

=back

=head1 DESCRIPTION

This library provides convient routines for writing Perl scripts to the
Baka standard. Mostly they deal with logging issues.

=head1 API

=over 6

=item B<bopen_log>

The routine opens a Baka log which is just an instancw of an
B<IO::File>. B<filename> is the name of the log. If <append> is set, then
the log will not be truncated when opened. B<error> is a F<Baka::Error>
handle. The F<IO::File> object will have autoflush turned on unless the
B<no_autoflush> argument is set.

=item B<berror>

Print B<msg> to a log opened by B<bopen_log> or to the I<err_print> method
of a B<Baka::Error> stream. B<berror> will ensure there is a line separator
at the end (ie the current value of F<$/>) unless the I<no_break>
parameter is set. B<berror> will automatically prepend the string "ERROR: "
to B<msg> unless the F<no_header> parameter is set.

=item B<bwarn>

Print B<msg> to a log opened by B<bopen_log> or to the I<err_print> method
of a B<Baka::Error> stream. B<bwarn> will ensure there is a line separator
at the end (ie the current value of F<$/>) unless the I<no_break>
parameter is set. B<bwarn> will automatically prepend the string "WARN: "
to B<msg> unless the F<no_header> parameter is set.

=item B<bdebug>

Print B<msg> to a log opened by B<bopen_log> or to the I<dprint> method of
a B<Baka::Error> stream. B<bdebug> will ensure there is a line separator at
the end (ie the current value of F<$/>) unless the I<no_break> parameter
is set. B<bdebug> will automatically prepend the string "DEBUG: " to B<msg>
unless the F<no_header> parameter is set.

=item B<bmsg>

Print B<msg> to a log opened by B<bopen_log> or to the I<dprint> method of
a B<Baka::Error> stream at the I<info> level. B<bdebug> will ensure there
is a line separator at the end (ie the current value of F<$/>) unless the
I<no_break> parameter is set. B<bmsg> will automatically prepend the
string "MSG: " to B<msg> unless the F<no_header> parameter is set.

=item B<bdie>

Call B<berror> with B<msg> and B<log> and then die with the optional
B<ecode> (1 by default). If B<want_stderr> has been set, then B<msg> will
also go to stderr.

=item B<bask>

Print B<msg> and wait for the user to reply. The reply is saved to the
B<reply_r> reference. If B<default> is specified, it is substituted for
emptry replies. If B<pattern> is specified, the question is reasked until
the reply matches B<pattern>. The question and answer are logged to B<log>.

=item B<bruncmd>

Run a UNIX shell command with the input and output logged. B<cmd> is the
shell command to run. It and the resulting exit code are always
logged. B<log> is either the return value of B<bopen_log> or a
F<Baka::Error> stream. If B<output_r> is an array reference the results are
returned as an array; if it is a scalar reference the result lines are
joined into a single string. B<retcode_r> is a copyout of the actual return
value. If B<ignore_error_code> is set, then exit codes of this value are
marked as being ignored. If B<success_code> is set, then this value (and
not 0) is taken as the indication of success. All output is logged unless
the B<ignore_output> argument is set.

=item B<want_stderr>

Indicate whether to print B<bdie> messages to stderr as well as the log.

=back

=head1 SEE ALSO

F<IO::File.pm>, F<Baka::Error.pm>

=head1 BUGS

"This library provides convient routines for writing Perl scripts to the Baka standard."
Baka B<standard>? B<What> Baka standard?

These routines should probably also provide an option to print messages to
standard out/error in addtion to the log.

=head1 AUTHOR

James Tanis

=cut

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
@EXPORT_OK = qw (berror bmsg bdebug bdie bruncmd bopen_log bwant_stderr bask);

my $want_stderr = 0;


################################################################
#
# Print an error message to an optional log or Baka::Error stream
#
sub berror($$;$$ )
{
  my($msg, $log, $no_break, $no_header) = @_;

  # Make sure the message a separator at the end.
  if (!$no_break)
  {
    chomp($msg);
    $msg .= $/;
  }

  if (ref($log) eq "Baka::Error")
  {
    $log->err_print($msg);
  }
  else
  {
    print $log ((!$no_header)?"ERROR: ":"") . "$msg";
  }

  return;
}



################################################################
#
# Print a warning message to an optional log or Baka::Error stream
#
sub bwarn($$;$$ )
{
  my($msg, $log, $no_break, $no_header) = @_;

  # Make sure the message a separator at the end.
  if (!$no_break)
  {
    chomp($msg);
    $msg .= $/;
  }

  if (ref($log) eq "Baka::Error")
  {
    $log->err_print($msg, 'warning');
  }
  else
  {
    print $log ((!$no_header)?"WARN: ":"") . "$msg";
  }

  return;
}



################################################################
#
# Print a message to an optional log or Baka::Error stream (at debug level)
#
sub bdebug($$;$$ )
{
  my($msg, $log, $no_break, $no_header) = @_;

  # Make sure the message a separator at the end.
  if (!$no_break)
  {
    chomp($msg);
    $msg .= $/;
  }

  if (ref($log) eq "Baka::Error")
  {
    $log->dprint($msg, 'debug');
  }
  else
  {
    print $log ((!$no_header)?"DEBUG: ":"") . "$msg";
  }

  return;
}



################################################################
#
# Print a message to an optional log or Baka::Error stream (at info level)
#
sub bmsg($$;$$ )
{
  my($msg, $log, $no_break, $no_header) = @_;

  # Make sure the message a separator at the end.
  if (!$no_break)
  {
    chomp($msg);
    $msg .= $/;
  }

  if (ref($log) eq "Baka::Error")
  {
    $log->dprint($msg, 'info');
  }
  else
  {
    print $log ((!$no_header)?"MSG: ":"") . "$msg";
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
  chomp(my @lines = `exec 2>/dev/stdout; $cmd`);
  $SIG{'CHLD'} = $old_chld if (defined($old_chld));

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


################################################################
#
# Ask a question with optional reply checking
#
sub bask($$$;$$)
{
  my($msg, $reply_r, $log, $default, $pattern) = @_;
  my $reply;

  my $query = "$msg" . (($default)?" [$default]":"");

  while (1)
  {
    print STDOUT "$query: ";
    chomp($reply = <STDIN>);

    $reply = "$default" if (defined($default) && ($reply eq ""));

    last if (!defined($pattern) || (eval "\$reply =~ $pattern"));
    # Note we log only $msg, not $query (too wordy)
    bmsg("$msg: $$reply", $log);
  }

  $$reply_r = $reply;
}

1;

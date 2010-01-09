######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2010 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
use strict;


package Baka::RT;

use constant
{
  BASE_PRIORITY => 30,
};


# If this isn't set to something, rt won't let you submit tickets
$ENV{'EDITOR'} = "cat" if (!exists($ENV{'EDITOR'}));

my($rt3);

{
  sub new($;$$$ )
  {
    my($self, $queue, $base_priority) = @_;
    my($class) = ref($self) || $self;

    $self = {};
    bless($self);

    if (-d "/usr/local/rt3")
    {
      $self->rtdir("/usr/local/rt3");
      $rt3 = 1;
      $ENV{'RTUSER'} = 'nightly';
      $ENV{'RTSERVER'} = 'http://rt.example.com';
      $ENV{'RTPASSWD'} = 'XXX';
    }
    else
    {
      $self->rtdir("/usr/local/rt2");
      $rt3 = 0;
    }
    $self->queue($queue) if (defined($queue));
    $self->base_priority(defined($base_priority)?$base_priority:BASE_PRIORITY);
    $self->{'no_rt_ticket'} = "NO_RT_TICKET";
    $self->cur_ticket("");
    $self->{'nobody'} = "Nobody";
    $self->{'limit'} = 0;

    return($self);
  }



  # Get/set the limit of how many lines may appear as text in the ticket.
  # This is only availalble in rt3;
  sub text_limit($;$ )
  {
    my($self, $limit) = @_;

    return (0) if (!$rt3);

    $self->{'limit'} = $limit if (defined($limit));
    return($self->{'limit'});
  }



  sub create_ticket($;$$$$$ )
  {
    my($self, $subject, $source, $queue, $base_priority, $owner) = @_;
    my($new_ticket);
    my($attachment_file, $cmd);
    my($ticket_file) = "/tmp/ticket_form";


    $queue = $self->queue if (!defined($queue));
    $base_priority = $self->{'base_priority'} if (!defined($base_priority));
    $subject = "Uknown subject" if (!defined($subject));
    $source = "/dev/null" if (!defined($source));
    $owner = $self->{'nobody'} if (!defined($owner));

    if ($rt3)
    {
      my($text, @text, $formatted, );
      my($min_index) = 0;

      $self->_execute_cmd("cat $source", \$text);

      if (@text = split(/\n/, $text))
      {
	if ($self->{'limit'} && ($#text > $self->{'limit'}))
	{
	  $attachment_file = "/tmp/attach";
	  open(FILE, "> $attachment_file") || goto error;
	  print FILE "" . join("\n", $text) . "\n";
	  close(FILE);

	  $min_index = $#text - $self->{'limit'} - 1;
	}

	$formatted = join("\n\t", $text[$min_index..$#text]);

	undef($text);
      }

      goto error if ($self->_execute_cmd(qq^$self->{'rt'} create -o -t ticket set subject="$subject" owner="$owner" priority="$base_priority" queue="$queue" status="new"^, \$text) < 0);

      open(FILE, "> $ticket_file") || goto error;
      print FILE "$text\n";
      print FILE "Text: $formatted\n" if ($formatted);
      close(FILE);

      $cmd = "cat $ticket_file | $self->{'rt'} create -i -t ticket | grep 'created' | awk '{ print \$3 }'";

#      $cmd = qq^self->{'rt'} create -o -t ticket set subject="$subject" owner="$owner" priority="$base_priority" queue="$queue" status="new" text="^ . $text . qq^" 2>/dev/null| grep 'created' | awk '{ print \$3 }'^;

    }
    else
    {
      $cmd = qq^$self->{'rt'} --create --noedit --subject="$subject" --owner="$owner" --priority="$base_priority" --queue="$queue" --status="new" --source="$source"  2>/dev/null | grep 'created in queue' | awk '{ print \$2 }' | uniq^;
    }

    goto error if (!defined($queue) || (($self->_execute_cmd($cmd, \$new_ticket)) < 0) || ($new_ticket eq""));

    if (defined($attachment_file))
    {
      # add attachment file. This is only for RT v. 3
      goto error if ($self->_execute_cmd("$self->{'rt'} comment -m 'The full details are attached' -a $attachment_file $new_ticket"));
    }

  error:
    unlink("$attachment_file") if (defined($attachment_file));
    unlink("$ticket_file") if (-f $ticket_file);
    return($new_ticket || -1);
  }


  sub search_for_ticket($$ )
  {
    my($self, $subject) = @_;
    my($cur_ticket, $cmd);

    if ($rt3)
    {
      $cmd = qq^$self->{'rt'} ls -t ticket -i "subject='$subject' and (status='new' or status='open')" 2>/dev/null| sed -e 's|ticket/||'^;
    }
    else
    {
      $cmd = qq^$self->{'rt'} --limit-subject="$subject" --limit-status="new" --limit-status="open" --summary='%id20' 2>/dev/null | sed '1d' | awk '{ print \$1 }'^;
    }

    $cur_ticket = "" if ($self->_execute_cmd($cmd, \$cur_ticket) < 0);

    return($self->cur_ticket($cur_ticket));
  }



  sub cur_ticket($;$ )
  {
    my($self, $cur_ticket) = @_;

    if (defined($cur_ticket))
    {
      if ($cur_ticket eq "")
      {
	$self->{'cur_ticket'} = $self->{'no_rt_ticket'};
      }
      else
      {
	$self->{'cur_ticket'} = $cur_ticket;
      }
    }

    return($self->{'cur_ticket'});
  }



  sub close_ticket($;$ )
  {
    my($self, $cur_ticket) = @_;
    my($ret, $cmd);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->{'no_rt_ticket'});

    if ($rt3)
    {
      $cmd = qq^$self->{'rt'} edit ticket/${cur_ticket} set status=resolved >/dev/null 2>&1^;
    }
    else
    {
      $cmd = qq^$self->{'rt'} --status="resolved" --id="$cur_ticket" >/dev/null 2>&1^;
    }

    return ($self->_execute_cmd($cmd));
  }



  sub valid_ticket($;$ )
  {
    my($self, $cur_ticket) = @_;

    $cur_ticket = $self->cur_ticket if (!defined($cur_ticket));

    return ($cur_ticket ne $self->{'no_rt_ticket'});
  }



  sub rtdir($;$ )
  {
    my($self, $rtdir) = @_;

    if (defined($rtdir))
    {
      $self->{'rtdir'} = $rtdir;
      $self->{'rt'} = "$rtdir/bin/rt";
    }
    return($self->{'rtdir'});
  }



  sub queue($;$ )
  {
    my($self, $queue) = @_;

    $self->{'queue'} = $queue if (defined($queue));
    return($self->{'queue'});
  }



  sub base_priority($;$ )
  {
    my($self, $base_priority) = @_;

    $self->{'base_priority'} = $base_priority if (defined($base_priority));
    return($self->{'base_priority'});
  }



  sub get_owner($;$ )
  {
    my($self, $cur_ticket) = @_;
    my($cur_owner, $cmd);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(undef) if ($cur_ticket eq $self->{'no_rt_ticket'});

    if ($rt3)
    {
      $cmd = qq^rt show ticket/${cur_ticket} -f owner | sed '1d' | awk -F: '{ print \$2 }' | tr -d ' ' 2>/dev/null^;
    }
    else
    {
      $cmd = qq^$self->{'rt'} --id="$cur_ticket" --summary='%owner100' 2>/dev/null | sed -e '1d' | tr -d ' '^;
    }


    $cur_owner = $self->{'nobody'} if ($self->_execute_cmd($cmd, \$cur_owner) < 0);

    return($cur_owner);
  }



  sub valid_owner($;$ )
  {
    my($self, $owner) = @_;

    return (defined($owner) && ($owner ne $self->{'nobody'}));
  }



  sub get_priority($;$ )
  {
    my($self, $cur_ticket) = @_;
    my($cur_priority, $cmd);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->{'no_rt_ticket'});

    if ($rt3)
    {
      $cmd = qq^rt show ticket/${cur_ticket} -f priority 2>/dev/null | sed '1d' | awk -F: '{ print \$2 }' | tr -d ' '^;
    }
    else
    {
      $cmd = qq^$self->{'rt'} --id="$cur_ticket" --summary='%priority100' 2>/dev/null | sed -e '1d' | tr -d ' '^;
    }

    $cur_priority = -1 if ($self->_execute_cmd($cmd, \$cur_priority) < 0);

    return($cur_priority);
  }



  sub set_priority($$;$ )
  {
    my($self, $priority, $cur_ticket) = @_;
    my($ret, $cmd);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if (!defined($priority) || !$self->valid_ticket($cur_ticket));

    if ($rt3)
    {
      $cmd = qq^$self->{'rt'} edit ticket/${cur_ticket} set priority="$priority" >/dev/null 2>&1^;
    }
    else
    {
      $cmd = qq^$self->{'rt'} --id="$cur_ticket" --priority="$priority" >/dev/null 2>&1^;
    }
    return ($self->_execute_cmd($cmd))
  }



  sub add_keywords($$;$ )
  {
    my($self, $keywords_listr, $cur_ticket) = @_;
    my($kw_args, $cmd);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return (-1) if (!defined($keywords_listr) || !$self->valid_ticket($cur_ticket));


    if ($rt3)
    {
      # You can't do this in bloody rt3. Not even as a separate transacton. Bastards.
      return(0);
    }
    else
    {
      $kw_args = join (" --keywords=", @$keywords_listr);
      $cmd = qq^$self->{'rt'} --id=$cur_ticket >/dev/null 2>&1^;
    }

    return($self->_execute_cmd($cmd));
  }



  sub verbose($;$ )
  {
    my($self, $verbose) = @_;

    $self->{'verbose'} = $verbose if (defined($verbose));
    return($self->{'verbose'});
  }



  sub no_execute($;$ )
  {
    my($self, $no_execute) = @_;

    $self->{'no_execute'} = $no_execute if (defined($no_execute));
    return($self->{'no_execute'});
  }



  ################################################################
  #
  # Execute shell commands. If 'no_execute' is set, do not actually
  # perform the action (but print out a mesage if 'verbose' is on).
  # Returns 0 on success, -1 on faiure.
  #
  sub _execute_cmd($$;$ )
  {
    my($self, $cmd, $outputr) = @_;
    my($output);
    my($ret) = 0;

    if (!$self->{'no_execute'})
    {
      print "Executing: **$cmd**\n" if ($self->{'verbose'});

      chomp($output = `$cmd`);

      print "Result: **$output**\n" if ($self->{'verbose'});

      $$outputr = $output if (defined($outputr));

      $ret = $? >> 8;
    }
    else
    {
      print "Suppressing execution of: **$cmd**\n" if ($self->{'verbose'});
    }

    return (!$ret?0:-1);
  }
}

1;

__END__;

=head1 NAME

Baka::RT -- Perl API to the RT ticketing system.

=head1 SYNOPSIS

=over 6

      use Baka::RT;

      $rt = Baka::RT->new;
      $rt = Baka::RT->new($queue_name, $base_priority);

      $rt->create_ticket($subject, $source);
      $rt->create_ticket($subject, $source, $queue, $base_priority);

      $rt->search_for_ticket($subject);

      $rt->cur_ticket;
      $rt->cur_ticket($ticket);

      $rt->close_ticket:
      $rt->close_ticket($ticket);

      $rt->valid_ticket;
      $rt->valid_ticket($ticket);

      $rt->rtdir;
      $rt->rtdir($dir);

      $rt->queue;
      $rt->queue($queue);

      $rt->base_priority;
      $rt->base_priority($priority);

      $rt->get_owner;
      $rt->get_owner($ticket);
      $rt->valid_owner($ticket);

      $rt->get_priority;
      $rt->get_priority($ticket);

      $rt->set_priority($priority);
      $rt->set_priority($priority, $ticket);

      $rt->add_keywords($keywords_list_ref);
      $rt->add_keywords($keywords_list_ref, $ticket);

      $rt->verbose;
      $rt->verbose(1);

      $rt->no_execute;
      $rt->no_execute(1);

      $rt->text_limit;
      $rt->text_limit(15);

=back

=head1 DESCRIPTION

=head1 API

=over 6

=item new

The contructor may be called with either no arguments to simply obtain the
object reference or with either (or both) I<queue_name> or
I<base_priority>. These two values will be used as defaults in
C<$rt-E<gt>create_ticket>. There is no default I<queue> (ie you have to
set it here, via the C<$rt-E<gt>queue> method, or when you invoke
C<$rt-E<gt>create_ticket>)

Returns the I<new object reference> on success; I<undef> on failure.

=item create_ticket

This creates a ticket. You may optionally pass in the I<subject>, the file
F<source> from which the body of the ticket will be obtained, the I<queue>,
the I<priority>, and the I<owner>.

Returns a I<ticket number> on success, I<-1> on failure.

=item search_for_ticket

Search for a ticket with the given I<subject>. This function has the side
effect of setting the located ticket as the current ticket for the object.

Returns the I<ticket number> on success; a I<special toket> on failure (see
alos the description of C<valid_ticket>).

=item close_ticket

Close the specified I<ticket> or the current ticket by default.

Returns I<0> on success; I<-1> on failure.

=item valid_ticket

Determines whether the supplied I<ticket> or the current ticket is valid.

B<NB> This method is a legacy of the old shell implementation. While it
will always be supported to maintain backwards compatibility it may by
obviated in the future.

Returns I<1> if the ticket is valid, I<0> otherwise.

=item rtdir

Set or retrieve the directory where the RT installation is located.

Returns the I<current directory> on success; I<undef> on failure.

=item queue

Set or retrieve the current default RT queue for new tickets.

Returns the I<current queue> on success; I<undef> on failure.

=item base_priority

Set or retrieve the current default priority for new tickets.

Returns the I<current base priority>. It cannot fail.

=item get_owner

Retrieve the owner the ticket. If a ticket is not supplied, it operates on
the current ticket.

Returns the I<owner name> on success; I<a special token> if there is no
onwer (see the I<valid_owner> method below); I<undef> on failure.

=item valid_owner

Determine if the result from I<get_owner> is a valid owner.

B<NB> This method is a legacy of the old shell implementation. While it
will always be supported to maintain backwards compatibility it may by
obviated in the future.

Returns I<1> if the owner is valid; I<0> otherwise.

=item get_priority

Retrieve the current priority of a ticket. If no ticket is specified, the
method operates on the current ticket.

Returns the I<priority> on success; I<-1> on failure..

=item set_priority

Set the priority of a ticket. If no ticket is specified, the method
operates on the current ticket.

Returns I<0> on success, I<-1> on failure.


=item add_keywords

Adds keywords to a ticket. If not ticket is specified, the the method
operates on the current ticket.  Keyword strings must be exactly the same
as the RT command line interface would accept (eg:
"+Impact/Broken"). The keyword argument must be a reference to an array of
keword strings (so all keywords may be inserted in one call).

Returns I<0> on success; I<-1> on failure.

=item verbose

Set or retrive the current state of verbose mode. Setting verbose to I<0>
turns off verbosity (the default setting). All other values turn it on.

Returns the I<current verbosity value>.

=item no_execute.

Set or retrive the current state of the "no execute" mode. Setting verbose
to I<0> turns off "no execute" (the default setting). All other values turn
it on.  In this mode (generally most useful with I<verbose>), the RT
operations will not actually execute.

B<NB> This method has not really ben tested.

Returns the I<current "no execute" value>.

=item text_limit

Set or retrieve the current text limit. If using RT version 3, you may
select the limit of of the number of lines which will be inserted into the
text portion of the ticket. If the output is longer than this, then the
B<final> N lines will appear in the text portion, and the entire text will
be attached.

Returns the I<current text limit>.

=back

=head1 AUTHOR

James Tanis (james.tanis@counterstorm.com)

=cut

use strict;


package Baka::RT;


# If this isn't set to something, rt won't let you submit tickets
$ENV{'EDITOR'} = "cat" if (!exists($ENV{'EDITOR'}));

{
  sub new($;$$$)
  {
    my($self, $queue, $base_priority) = @_;
    my($class) = ref($self) || $self;

    $self = {};
    bless($self);

    $self->rtdir("/usr/local/rt2");
    $self->queue($queue) if (defined($queue));
    $self->base_priority(defined($base_priority)?$base_priority:30);
    $self->{'no_rt_ticket'} = "NO_RT_TICKET";
    $self->cur_ticket("");
    $self->{'nobody'}="Nobody";
    
    return($self);
  }



  sub create_ticket($;$$$$)
  {
    my($self, $subject, $source, $queue, $base_priority) = @_;
    my($new_ticket);

    $queue = $self->queue if (!defined($queue));
    $base_priority = $self->{'base_priority'} if (!defined($base_priority));
    $subject = "Uknown subject" if (!defined($subject));
    $source = "/dev/null" if (!defined($source));

    return (-1) if (!defined($queue) || ($self->_execute_cmd("$self->{'rt'} --create --noedit --subject=\"$subject\" --owner=\"$self->{'nobody'}\" --priority=\"$base_priority\" --queue=\"$queue\" --status=\"new\" --source=\"$source\"  2>/dev/null | grep 'created in queue' | awk '{ print \$2 }' | uniq", \$new_ticket)) < 0);

    return ($new_ticket);
  }


  sub rtdir($;$)
  {
    my($self, $rtdir) = @_;

    if (defined($rtdir)) 
    {
      $self->{'rtdir'} = $rtdir;
      $self->{'rt'} = "$rtdir/bin/rt";
    }
    return($self->{'rtdir'});
  }



  sub queue($;$)
  {
    my($self, $queue) = @_;

    $self->{'queue'} = $queue if (defined($queue));
    return($self->{'queue'});
  }



  sub cur_ticket($;$)
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



  sub verbose($;$)
  {
    my($self, $verbose) = @_;

    $self->{'verbose'} = $verbose if (defined($verbose));
    return($self->{'verbose'});
  }



  sub no_execute($;$)
  {
    my($self, $no_execute) = @_;

    $self->{'no_execute'} = $no_execute if (defined($no_execute));
    return($self->{'no_execute'});
  }



  sub base_priority($;$)
  {
    my($self, $base_priority) = @_;

    $self->{'base_priority'} = $base_priority if (defined($base_priority));
    return($self->{'base_priority'});
  }



  sub search_for_ticket($$)
  {
    my($self, $subject) = @_;
    my($cur_ticket);

    $cur_ticket = "" if ($self->_execute_cmd("$self->{'rt'} --limit-subject=\"$subject\" --limit-status=\"new\" --limit-status=\"open\" --summary='%id20' 2>/dev/null | sed '1d' | awk '{ print \$1 }'", \$cur_ticket) < 0);

    return($self->cur_ticket($cur_ticket));
  }



  sub valid_ticket($;$)
  {
    my($self, $cur_ticket) = @_;

    $cur_ticket = $self->cur_ticket if (!defined($cur_ticket));

    return ($cur_ticket ne $self->{'no_rt_ticket'});
  }



  sub valid_owner($;$)
  {
    my($self, $owner) = @_;

    return (defined($owner) && ($owner ne $self->{'nobody'}));
  }



  sub close_ticket($;$)
  {
    my($self, $cur_ticket) = @_;
    my($ret);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->{'no_rt_ticket'});

    return ($self->_execute_cmd("$self->{'rt'} --status=\"resolved\" --id=\"$cur_ticket\" >/dev/null 2>&1"));
  }



  sub get_owner($;$)
  {
    my($self, $cur_ticket) = @_;
    my($cur_owner);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(undef) if ($cur_ticket eq $self->{'no_rt_ticket'});

    $cur_owner = $self->{'nobody'} if ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --limit-status=\"open\" --limit-status=\"new\" --summary='%owner100' 2>/dev/null | sed -e '1d' | tr -d ' '", \$cur_owner) < 0);
    
    return($cur_owner);
  }



  sub get_priority($;$)
  {
    my($self, $cur_ticket) = @_;
    my($cur_priority);
  
    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->{'no_rt_ticket'});

    $cur_priority = -1 if ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --limit-status=\"open\" --limit-status=\"new\" --summary='%priority100' 2>/dev/null | sed -e '1d' | tr -d ' '", \$cur_priority) < 0);
    
    return($cur_priority);
  }



  sub set_priority($$;$)
  {
    my($self, $priority, $cur_ticket) = @_;
    my($ret);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if (!$self->valid_ticket($cur_ticket));

    return ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --priority=\"$priority\" >/dev/null 2>&1"))
  }



  sub add_kewords($$$)
  {
    my($self, $keywords_listr, $cur_ticket) = @_;
    my($kw_args);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return (-1) if (!defined($keywords_listr) || !$self->valid_ticket($cur_ticket));

    $kw_args = join (" --keywords=", @$keywords_listr);
    
    return($self->_execute_cmd("$self->{'rt'} --id=$cur_ticket --keywords=$kw_args >/dev/null 2>&1"));
  }



  sub _execute_cmd($$;$)
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

      $rt->get_priority;
      $rt->get_priority($ticket);

      $rt->set_priority($priority);
      $rt->set_priority($priority, $ticket);

      $rt->add_kewords($keywords_list_ref);
      $rt->add_kewords($keywords_list_ref, $ticket);

      $rt->verbose;
      $rt->verbose(1);

      $rt->no_execute;
      $rt->no_execute(1);

=back

=head1 DESCRIPTION

=head1 API

=over 6

=item new

The contructor may be called with either no arguments to simply obtain the
object reference or with either (or both) I<queue_name> or
I<base_priority>. These two values will be used as defaults in
C<$self-E<gt>create_ticket>). There is no default I<queue> (ie you have to
set it here, via the C<$self-E<gt>queue> method, or when you invoke
C<$self-E<gt>create_ticket>)

Returns the I<new object reference> on success; I<undef> on failure.

=item create_ticket

This creates a ticket. You may optionally pass in the I<subject>, the file
F<source> from which the body of the ticket will be obtained, the I<queue>,
and the I<priority>.

Returns the I<ticket number> on success, I<-1> on failure.

=item search_for_ticket

Search for a ticket with the given I<subject>. This function has the side
effect of setting the located ticket as the default ticket for the object.

Returns the I<ticket number> on success; a I<special toket> on failure (see
alos the description of C<valid_ticket>).

=item close_ticket

Close the specified I<ticket> or the current ticket by default.

Returns I<0> on success; I<-1> on failure.

=item valid_ticket

Determines whether the supplied I<ticket> or the current ticket is valid. 

Returns I<1> if the ticket is valid, I<0> otherwise.

=back

=head1 AUTHOR

James Tanis (jtt@sysd.com)

=cut


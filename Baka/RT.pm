use strict;


package Baka::RT;


# If this isn't set to something, rt won't let you submit tickets
$ENV{'EDITOR'} = "cat" if (!exists($ENV{'EDITOR'}));

{
  sub new($;$$$$)
  {
    my($self, $queue, $base_priority, $flags) = @_;
    my($class) = ref($self) || $self;

    $self = {};
    bless($self);

    $self->rtdir("/usr/local/rt2");
    $self->queue($queue) if (defined($queue));
    $self->base_priority(defined($base_priority)?$base_priority:30);
    $self->{'no_rt_ticket'} = "NO_RT_TICKET";
    $self->{'nobody'}="Nobody";
    
    return($self);
  }



  sub rtdir($;$)
  {
    my($self, $rtdir) = @_;

    if (defined($rtdir)) {
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

    if (defined($cur_ticket)) {
      if ($cur_ticket eq "") {
	$self->{'cur_ticket'} = $self->{'no_rt_ticket'};
      } else {
	$self->{'cur_ticket'} = $cur_ticket;
      }

    }

    return($self->{'cur_ticket'});
  }



  sub verbose($)
  {
    my($self, $verbose) = @_;

    $self->{'verbose'} = $verbose if (defined($verbose));
    return($self->{'verbose'});
  }



  sub no_execute($)
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



  sub create_ticket($$$;$$)
  {
    my($self, $subject, $source, $queue, $base_priority) = @_;
    my($new_ticket);

    $queue = $self->{'my_queue'} if (!defined($queue));
    $base_priority = $self->{'base_priority'} if (!defined($base_priority));
    $subject = "Uknown subject" if (!defined($subject));
    $source = "/dev/null" if (!defined($source));

    return (-1) if (!defined($queue) || ($self->_execute_cmd("$self->{'rt'} --create --noedit --subject=\"$subject\" --owner=\"$self->{'nobody'}\" --priority=\"$base_priority\" --queue=\"$queue\" --status=\"new\" --source=\"$source\"  2>/dev/null | grep 'created in queue' | awk '{ print \$2 }' | uniq") < 0));

    return (0);
  }



  sub close_ticket($;$)
  {
    my($self, $cur_ticket) = @_;
    my($ret);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->{'no_rt_ticket'});

    return ($self->_execute_cmd("$self->{'rt'} --status=\"resolved\" --id=\"$cur_ticket\" >/dev/null 2>&1"));
  }



  sub get_ticket_owner($;$)
  {
    my($self, $cur_ticket) = @_;
    my($cur_owner);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->no_rt_ticket);

    $cur_owner = $self->{'nobody'} if ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --limit-status=\"open\" --limit-status=\"new\" --summary='%owner100' 2>/dev/null | sed -e '1d' | tr -d ' '", \$cur_owner) < 0);
    
    return($cur_owner);
  }



  sub get_ticket_priority($;$)
  {
    my($self, $cur_ticket) = @_;
    my($cur_priority);
  
    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->no_rt_ticket);

    $cur_priority = -1 if ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --limit-status=\"open\" --limit-status=\"new\" --summary='%priority100' 2>/dev/null | sed -e '1d' | tr -d ' '", \$cur_priority) < 0);
    
    return($cur_priority);
  }



  sub set_priority($$;$)
  {
    my($self, $priority, $cur_ticket) = @_;
    my($ret);

    $cur_ticket = $self->{'cur_ticket'} if (!defined($cur_ticket));
    return(-1) if ($cur_ticket eq $self->no_rt_ticket);

    return ($self->_execute_cmd("$self->{'rt'} --id=\"$cur_ticket\" --priority=\"$priority\" >/dev/null 2>&1"))
  }



  sub _execute_cmd($$;$)
  {
    my($self, $cmd, $outputr) = @_;
    my($output);
    my($ret) = 0;
  
    if (!$self->{'no_execute'}) {
      print "Executing: **$cmd**\n" if ($self->{'verbose'});

      chomp($output = `$cmd`);

      print "Result: **$output**\n" if ($self->{'verbose'});

      $$outputr = $output if (defined($outputr));

      $ret = $? >> 8;
    } else {
      print "Suppressing execution of: **$cmd**\n" if ($self->{'verbose'});
    }
  
    return (!$ret?0:-1);
  }
}
1;

use strict;

# 
# start		: directive_list
# directive_list: directive SEMICOLON directive_list | <null>
# directive	: STRING EQUALS block
# block		: LEFT_BRACE directive_list RIGHT_BRACE | STRING
# 
# start = 
# { 
#   name = "this is token"; 
#   description = "this is another token";
# };
# 
# next = 
# { 
#   first_sub_directive =
#   { 
#     name = "First subdirective name";
#     description = "First subdirective description";
#   };
# 
#   second_sub_directive =
#   { 
#     name = "Second subdirective name";
#     description = "Second subdirective description";
#   };
# };
# 
# final = "simple token";
#

package Baka::StructuredConf;

use constant
{
  # Lexical tokens
  STRING 		=>	1,
  EQUALS		=>	2,
  LEFT_BRACE		=>	3,
  RIGHT_BRACE		=>	4,
  EOF			=>	5,
  ERROR			=>	6,
  SEMICOLON		=>	7,
  DEBUG_FLAG_LEX	=>	1,
};

{
  # Constructor
  sub new($;$)
  {
    my($self, $filename) = @_;
    my($class) = ref($self) || $self;

    $self = {};
    bless($self);

    if (defined($filename))
    {
      $self->{'filename'} = $filename;
      $self->parse_file;
    }
    $self->{'debug'} = 0;
    $self->{'saw_eol'} = 0;

    return($self);
  }


  # Set and get the string version of the file
  sub string($;$)
  {
    my($self, $string) = @_;

    $self->{'string'} = $string if (defined($string));
    
    return($self->{'string'});
  }



  # Set and get debug value
  sub debug($;$)
  {
    my($self, $debug_level) = @_;

    $self->{'debug'} = $debug_level if (defined($debug_level));
    
    return($self->{'debug'});
  }



  # Parse 	
  sub parse_string($;$)
  {
    my($self, $string) = @_;

    $string = $self->string("$string");

    if (!defined($string))
    {
      $self->error("Parse string is undefined");
      return(-1);
    }
    
    $self->{'pos'} = 0;
    $self->{'line'} = 1;
    $self->{'length'} = length($string);
    
    return($self->_start);
  }



  # Parse a file
  sub parse_file($;$)
  {
    my($self, $filename) = @_;
    my($old_sep) = $/;
    my($ret);
    
    $filename = $self->{'filename'} if (!defined($filename));

    if (!defined($filename))
    {
      $self->error("Filename is not defined");
      return(-1);
    }	
    
    if (!open(F, "< $filename"))
    {
      $self->error("Could not open $filename for reading: $!");
      return(-1);
    }

    undef($/);
    $ret = $self->parse_string(<F>);
    close(F);
    $/ = $old_sep;

    return($ret);
  }

  # Actually do the parse
  sub _start($;)
  {
    my($self) = @_;

    return (-1) if ($self->_directive_list < 0);
      
    if ($self->_get_token != EOF)
    {
      $self->parse_error("Failed parse");
      return(-1);
    }

    return(0);
  }	       


  sub _directive_list($;)
  {
    my($self) = @_;
    my($tok);
    
    while(1)
    {
      return (-1) if ($self->_directive < 0);

      if (($tok = $self->_get_token) != SEMICOLON)
      {
	$self->_push_token($tok);
	return(0);
      }
    }
  }



  sub _directive($;)
  {
    my($self) = @_;
    my($name, $tok);

    if (($tok = $self->_get_token) != STRING)
    {
      $self->_push_token($tok);
      return(0);
    }
    
    $name = $self->{'token_value'};

    print "Found name: **$name**\n";

    if (($tok = $self->_get_token) != EQUALS)
    {
      $self->_push_token(STRING, $name);
      $self->_push_token($tok);
      return(0);
    }

    return ($self->_block)
  }



  sub _block($)
  {
    my($self) = @_;
    my($tok);
    
    if (($tok = $self->_get_token) == LEFT_BRACE)
    {
      return (-1) if ($self->_directive_list < 0);
      
      if (($tok = $self->_get_token) != RIGHT_BRACE)
      {
	$self->_push_token($tok);
      }
    }
    elsif ($tok == STRING)
    {
      print "Found simple value: **$self->{'token_value'}**\n";
    }
    else
    {
      $self->_push_token($tok);
    }

    # Finish off directive.

    return(0);
  }


  # Push back a unneeded tokens;
  sub _push_token($$;$)
  {
    my($self, $token, $value) = @_;
    my($r);

    $r->{'token'} = $token;
    $r->{'value'} = $value if (defined($value));

    # If we've pulled off a string we don't want, we have to also push 
    # back the string value we probably don't know about.
    $r->{'value'} = $self->{'token_value'} if (($token == STRING) && !defined($value));

    if ($self->{'debug'} & DEBUG_FLAG_LEX)
    {
      print "LEX: PUSH: $token";
      print ": $value" if (defined($value));
      print "\n";
    }
      
    push @{$self->{'token_stack'}}, $r;
    return;
  }


  # Log an error;
  sub error($;$)
  {
    my($self, $error_string) = @_;

    if (defined($error_string))
    {
      $self->{'error'} .= "$/" if (defined($self->{'error'}));
      $self->{'error'} .= "$error_string";
    }
    
    return($self->{'error'});
  }

  # Log a parse error;
  sub parse_error($;$)
  {
    my($self, $error_string) = @_;
    my($source);

    if (defined($self->{'filename'}))
    {
      $source = $self->{'filename'};
    }
    else
    {
      $source = "input";
    }

    return($self->error("$error_string around line $self->{'line'} of $source"));
  }



  # Send up lexical tokens
  sub _get_token($)
  {
    my($self) = @_;
    my($char, $old_token);
    my($look);

    if (defined($old_token = pop(@{$self->{'token_stack'}})))
    {
      $self->{'token_value'} = $old_token->{'token_value'} if (defined($old_token->{'token_value'}));

      if ($self->{'debug'} & DEBUG_FLAG_LEX)
      {
	print "LEX: POP : $old_token->{'token'}" ;
	print ": $old_token->{'token_value'}" if (defined($old_token->{'token_value'}));
	print "\n";
      }
      return($old_token->{'token'});
    }

    # Skip leading whitspace.
    while((defined($char = $self->_next_char)) && ($char =~ /\s/)){}

    if (defined($char) && ($char eq "#"))
    {
      if (defined($char = $self->_next_char))
      {
	while((defined($char = $self->_next_char)) && ($char ne "\n")) {}
      }
    }

    if (!defined($char))
    {
      print "LEX: Returning EOF\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(EOF);
    }
    
    my($start) = $self->{'pos'} - 1;
    if ($char =~ /[\"\'\`]/)
    {
      # looking for a quoted string.
      $start++; # Advance the starting position of the string.
      while((defined($look = $self->_next_char)) && ($look ne $char)){}
      
      if (!defined($look))
      {
	my($strlen) = $self->{'pos'} - $start;
	my($substr);
	my($elipses) = "";

	if ($strlen > 20)
	{
	  # Add elispes to error message if substr is too long (fix substr at 20 chars).
	  $elipses = "...";
	  $strlen = 20;
	}
	
	chomp($substr = substr($self->string, $start, $strlen) . "$elipses");

	$self->parse_error("Premature EOF. Possible runaway string near \"$substr\"");
	print "LEX: Returning ERROR" if ($self->{'debug'} & DEBUG_FLAG_LEX);
	return(ERROR);
      }
      
      chomp($self->{'token_value'} = substr($self->string, $start, $self->{'pos'} - $start -1));
      print "LEX: Returning STRING: **$self->{'token_value'}**\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);

      return(STRING);
    }
    elsif ($char eq "{")
    {
      print "LEX: Returning LEFT_BRACE\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(LEFT_BRACE);
    }
    elsif ($char eq "}")
    {
      print "LEX: Returning RIGHT_BRACE\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(RIGHT_BRACE);
    }
    elsif ($char eq "=")
    {
      print "LEX: Returning EQUALS\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(EQUALS);
    }
    elsif ($char eq ";")
    {
      print "LEX: Returning SEMICOLON\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(SEMICOLON);
    }
    else
    {
      while((defined($look = $self->_next_char)) && ($look !~ /[\s{}=;]/)){}
      
      if (!defined($look))
      {
	# We probably can't reach this code actually.
	$self->parse_error("Premature EOF");
	print "LEX: Returning ERROR\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
	return(ERROR);
      }
      
      chomp($self->{'token_value'} = substr($self->string, $start, $self->{'pos'} - $start - 1));
      print "LEX: Returning STRING: **$self->{'token_value'}**\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(STRING);
    }

    $self->parse_error("Parser reached illegal state");
    print "LEX: Returning ERROR\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
    return(ERROR);
  }

	
  sub _next_char($)
  {
    my($self) = @_;

    undef($self->{'char'});
    
    if ($self->{'pos'} < $self->{'length'})
    {
      $self->_get_char;
      $self->{'pos'}++;

      # If you see a new line, mark that fact, so that line cnt can be updated on the *next* char.
      if ($self->{'char'} eq "\n")
      {
	$self->{'saw_eol'} = 1;
      }
      else
      {
	$self->{'line'}++ if ($self->{'saw_eol'});
	$self->{'saw_eol'} = 0;
      }

    }
    
    return($self->{'char'});
  }


  sub _get_char($)
  {
    my($self) = @_;
    
    $self->{'char'} = substr($self->string, $self->{'pos'}, 1);

    return(0);
  }
}

1;

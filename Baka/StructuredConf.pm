use strict;

# 
# start: directive_list
# 
# directive_list: directive
#                 | directive, directive_list
# 
# directive:      STRING EQUALS block SEMICOLON
# 
# block: LEFT_BRACE directive_list RIGHT_BRACE
#         | STRING
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
  STRING 	=>	1,
  EQUALS	=>	2,
  LEFT_BRACE	=>	3,
  RIGHT_BRACE	=>	4,
  EOF		=>	5,
  ERROR		=>	6,
  SEMICOLON	=>	7,
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

    return($self);
  }


  # Set and get the string version of the file
  sub string($;$)
  {
    my($self, $string) = @_;

    $self->{'string'} = $string if (defined($string));
    
    return($self->{'string'});
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
    
    
    return(0);
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
    my($char);

    # Skip leading whitspace.
    while((defined($char = $self->_next_char)) && ($char =~ /\s/)){}

    return(EOF) if (!defined($char));

    my($start) = $self->{'pos'} - 1;
    if ($char =~ /[\"\'\`]/)
    {
      my($look); # lookahead.
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
	return(ERROR);
      }
      
      chomp($self->{'token_value'} = substr($self->string, $start, $self->{'pos'} - $start -1));
      return(STRING);
    }
    elsif ($char eq "{")
    {
      return(LEFT_BRACE);
    }
    elsif ($char eq "}")
    {
      return(RIGHT_BRACE);
    }
    elsif ($char eq "=")
    {
      return(EQUALS);
    }
    else
    {
      my($look);
      
      while((defined($look = $self->_next_char)) && ($look !~ /[\s{}=]/)){}
      
      if (!defined($look))
      {
	# We probably can't reach this code actually.
	$self->parse_error("Premature EOF");
	return(ERROR);
      }
      
      chomp($self->{'token_value'} = substr($self->string, $start, $self->{'pos'} - $start));
      return(STRING);
    }

    $self->parse_error("Parser reached illegal state");
    return(ERROR);
  }

	
  sub _next_char($)
  {
    my($self) = @_;

    undef($self->{'char'});
    
    if ($self->{'pos'} < $self->{'length'})
    {
      $self->_get_char;
      $self->{'line'}++ if ($self->{'char'} eq "\n");
      $self->{'pos'}++;
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

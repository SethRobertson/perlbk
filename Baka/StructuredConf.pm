package Baka::StructuredConf;
use strict;
use FileHandle;


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


# Characters which stop the current round of tokenization
my($separator_chars) = '\n\s\{\}\=\;\#';

{
  # Constructor
  sub new($;$$)
  {
    my($self, $filename, $error) = @_;
    my($class) = ref($self) || $self;

    $self = {};
    bless($self);

    $self->{'debug'} = 0;
    $self->{'saw_eol'} = 0;

    if (defined($filename))
    {
      $self->{'filename'} = $filename;
      if ($self->parse_file < 0)
      {
	$$error = $self->error if (defined($error));
	undef($self);
      }
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

    if (!defined($string = $self->string("$string")))
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

    $self->{'tree'} = $self->_directive_list;

    if ($self->_get_token != EOF)
    {
      $self->_parse_error("Failed parse");
      return(-1);
    }
    
    return(0);
  }	       



  sub _directive_list($;)
  {
    my($self) = @_;
    my($tok, $ret);
    my($tree);

    $tree = {};
    
    while(1)
    {
      $ret = $self->_directive;

      if (($tok = $self->_get_token) != SEMICOLON)
      {
	$self->_push_token($tok);
	return($tree);
      }
      
      $tree->{$ret->{'key'}} = $ret->{'value'} if (defined($ret));

      push(@{$tree->{'_keys'}}, $ret->{'key'});
    }
    return($tree);
  }



  sub _directive($;)
  {
    my($self) = @_;
    my($ret, $tok);

    if (($tok = $self->_get_token) != STRING)
    {
      $self->_push_token($tok);
      return(undef);
    }
    
    $ret = {};
    $ret->{'key'} = $self->{'token_value'};

    if (($tok = $self->_get_token) != EQUALS)
    {
      $self->_push_token(ERROR);
      return(undef);
    }
    
    return(undef) if (!defined($ret->{'value'} = $self->_block));
    return($ret);
  }



  sub _block($)
  {
    my($self) = @_;
    my($tok, $ret);
    
    undef($ret);
    
    if (($tok = $self->_get_token) == LEFT_BRACE)
    {
      $ret = $self->_directive_list;
      
      if (($tok = $self->_get_token) != RIGHT_BRACE)
      {
	#$self->_push_token($tok);
	$self->_push_token(ERROR);
	return(undef);
      }
    }
    elsif ($tok == STRING)
    {
      my($localized_copy) = $self->{'token_value'};
      $ret = \$localized_copy;
    }
    else
    {
      $self->_push_token($tok);
      $ret = undef;
    }

    # Finish off directive.

    return($ret);
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
  sub error($;$$)
  {
    my($self, $error_string, $skip_frame) = @_;

    $skip_frame = 0 if (!defined($skip_frame));

    if (defined($error_string))
    {
      $self->{'error'} .= "$/" if (defined($self->{'error'}));
      $self->{'error'} .= "In function " . (caller ($skip_frame + 1))[3] . ": $error_string";
    }
    
    return($self->{'error'});
  }

  # Log a parse error;
  sub _parse_error($;$)
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

    return($self->error("$error_string around line $self->{'line'} of $source ", 1));
  }



  # Send up lexical tokens
  sub _get_token($)
  {
    my($self) = @_;
    my($char, $old_token);
    my($look, $skipped_something);

    # Check the token stack for pushed tokens. Return if found.
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

    # Get next character (unless we have to skip something).
    $char = $self->_next_char;

    # Skip leading whitspace and comments
    do
    {
      $skipped_something = 0;
      while (defined($char) && ($char =~ /\s/))
      {
	$skipped_something = 1;
	$char = $self->_next_char;
      }

      if (defined($char) && ($char eq "#"))
      {
	$skipped_something = 1;
	$char = $self->_next_char;
	while(defined($char) && ($char ne "\n"))
	{
	  $char = $self->_next_char;
	}
	$char = $self->_next_char;
      }
    } while ($skipped_something);

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

	$self->_parse_error("Premature EOF. Possible runaway string near \"$substr\"");
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
      while((defined($look = $self->_next_char)) && ($look !~ /[$separator_chars]/)){}
      
      if (!defined($look))
      {
	# We probably can't reach this code actually.
	$self->_parse_error("Premature EOF");
	print "LEX: Returning ERROR\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
	return(ERROR);
      }
      
      $self->{'pos'}--;
      chomp($self->{'token_value'} = substr($self->string, $start, $self->{'pos'} - $start));
      print "LEX: Returning STRING: **$self->{'token_value'}**\n" if ($self->{'debug'} & DEBUG_FLAG_LEX);
      return(STRING);
    }

    $self->_parse_error("Parser reached illegal state");
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



  # Write out a configuration file to disk. NB: COMMENTS ARE LOST!!! 
  sub write_file($$)
  {
    my($self, $filename) = @_;
    my($handle) = FileHandle->new;
    my($ret);
    
    if (!defined($filename))
    {
      $self->error("Illegal arguments");
      return (-1);
    }

    if (!defined($handle->open(">$filename")))
    {
      $self->error("Could not open \"$filename\" for writing: $!");
      return(-1);
    }

    $ret = $self->_print_tree($self->{'tree'}, $handle, "");

    $handle->close;

    return($ret);
  }




  # Recursively print parse tree to file. Also illustrative of how to traverse the tree
  sub _print_tree($$$$)
  {
    my($self, $tree, $handle, $indent) = @_;
    my($key);

    if (!defined($handle) || !defined($indent))
    {
      $self->error("Illegal arugments");
      return(-1);
    }

    foreach $key ($self->keys($tree->))
    {
      print $handle "$indent$key = ";
      if (ref($tree->{$key}) eq "SCALAR")
      {
	print $handle "\"${$tree->{$key}}\";\n";
      }
      else
      {
	print $handle "\n";
	print $handle "$indent\{\n";
	return (-1) if ($self->_print_tree($tree->{$key}, $handle, "\t$indent") < 0);
	print $handle "$indent\};\n\n";
      }
    }
    return(0);
  }

  sub keys($$)
  {
    my($self,$tree) = @_;

    return(undef) if (!defined($tree));

    return(@{$tree->{'_keys'}})
  }

}


1;


__END__

=head1 NAME

Baka::StructuredConf - Use a hierarchical configuration file.

=head1 SYNOPSIS

=over 6
      use Baka::StructuredConf;

      $conf = Baka::StructuredConf->new;
      $conf = Baka::StructuredConf->new(filename,\$error);

      $parse_ok = $conf->parse;
      $parse_ok = $conf->parse($conf_file_lines);
      $parse_ok = $conf->parse_file($filename);

      $conf->keys($subree_hash_ref);

      $conf_file_lines = $conf->string;
      $conf->string($adjusted_conf_file_lines);

      $debug = $conf->debug;
      $conf->debug(1);

      $write_ok = $conf->write_file($filename);

      $error_string = $conf->error;

=back

=head1 DESCRIPTION

This module provides an API for using and managing a configuration file
where the entries have a hierarchical relationship. It produces a reference
to a hash whose members are all either hash references to the lext "level"
or a scalar reference to a string. Blank lines are ignored as is all text
begining with a hash(#) and continuing to the next NEWLINE.

Traversing the tree is very easy. At each level you call
C<$self-E<gt>keys($hash_ref)> to get the list of valid keys at that level
(in top-down order). For each key you check the value. if it's a hash you
"recurse" down to the next level (ie that becomes the new argument to
C<$self-E<gt>keys>); if it's a scalar reference you dereference it for the
value of the key.

=head1 API

=over 6

=item new

The contsructor may be called to simply create the object or may optionally
pass in a F<filename> to be parsed. In addition you may pass in a scalar
reference which will be filled out with the error string should an error
occr. Once the object is created, all errors are retrieved via
C<$self-E<gt>error>.

Returns an I<object reference> on success; I<undef> on failure.

=item parse

Takes a I<string> which contains the text of a configuration file and parses
it. If the I<string> is not defined, it parse the current value of
C<$self-E<gt>string>. 

Returns a I<hash reference> on success; I<undef> on failure.

=item parse_file

Like C<$self-E<gt>parse($string)> but takes a F<filename> instead.

Returns a I<hash reference> on success; I<undef> on failure.

=item keys

Returns the list of valid keys at the "level" of I<$subtree_hash_ref>. While this is essentially the same thing as (keys %$subtree_hash_ref), it differs in two respects:

=over 3

=item 1

It does not return the internally used I<_keys> key.

=item 2

It returns the keys in the top-down order in which they were parsed. Using perl's C<keys> command will not do that.

=back

=item string

Retrieve or modify the string representing the configuration file. If you
modify the string, you will have to reparse later.

Returns the I<configuration file string> on success; I<undef>x on failure.

=item debug

Set or retrive the current debug value. I<0> turns off debuggin; all other
values turn debugging on.

Returns the current I<debugging value>; it cannot fail

=item write_file

Write the current (possibly modified) confguration string out to
F<filename>. Comments, if there were any, will be lost!

Returns I<0> on success; I<-1> on failure.

=item error

Returns the I<current error string>; it cannot fail.


=back       

=head1 BAKUS-NAUR FORM

The following the BNF of the grammar for the file.

    start		: directive_list
    directive_list	: directive ';' directive_list | <epsilon>
    directive		: STRING '=' block
    block		: '{' directive_list '}' | STRING

Where STRING may be either a single word (ie wods containing no white space
or reserverd characters: semicolons, braces, and equals) or multiple words
bracketed by matching quotes (of any type). You may of course quote single
words as well.

NB: This means that keys (ie: words to the left an '=') may be multiple
words surrounded by quotes, though typically they are single words.

=head1 EXAMPLE FILE

    start = 
    { 
      name = "this is token"; 
      description = "this is another token";
    };
    
    next = 
    { 
      first_sub_directive =
      { 
        name = "First subdirective name";
        description = "First subdirective description";
      };
    
      second_sub_directive =
      { 
        name = "Second subdirective name";
        description = "Second subdirective description";
      };
    };
    
    final = "simple token";

=head1 NOTES

The source for C<$self-E<gt>write_tree> (or really the internal function
C<_print_tree>) is a very easy way to learn the strucuture of the hash tree
which is returned and how to traverse it.

=head1 BUGS

It's not clear or promised that C<$self-E<gt>debug(1)> does anything useful.

It's not celar that making the string values *also* be references
accomplishes anything useful. But it *definitely* confuses people.

=head1 AUTHOR

James Tanis (jtt@sysd.com)
 
=cut

######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2004-2008 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
# An example template to show the environment you have
#

sub template_helloworld($$)
{
  my ($Inforef, $StateRef) = @_;
  my (@Output);
  my ($key);

  push(@Output, "                                Hello World!!!\n\n");
  push(@Output, "List of Info keys and variables (many will be references)\n");
  foreach $key (sort keys %$Inforef)
  {
    my ($foo);
    my ($bar);
    if ($key eq "CmdLine")
    {
      foreach $foo (keys %{$Inforef->{$key}})
      {
	push(@Output, "$key: $foo: $Inforef->{$key}->{$foo}\n");
      }
    }
    elsif ($key eq "Loaded")
    {
      foreach $foo (keys %{$Inforef->{$key}})
      {
	foreach $bar (keys %{$Inforef->{$key}->{$foo}})
	{
	  push(@Output, "$key: ${foo}_$bar\n");
	}
      }
    }
    elsif ($key eq "OutputList")
    {
      foreach $foo (@{$Inforef->{$key}})
      {
	push(@Output, "$key: $foo\n");
      }
    }
    else
    {
      push(@Output, "$key: $Inforef->{$key}\n");
    }
  }
  push(@Output, "\n\n");
  push(@Output, sprintf("This function has been called %d times\n",$StateRef->{'count'}++));

  main::OutputAll($Inforef, "Hello World", \@Output);
}

1;

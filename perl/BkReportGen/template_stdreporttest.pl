######################################################################
#
# ++Copyright LIBBK++
#
# Copyright (c) $YEAR The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Mail <projectbaka\@baka.org> for further information
#
# --Copyright LIBBK--
#
# An example template for standard reports
#

sub template_stdreporttest($$)
{
  my ($Inforef, $StateRef) = @_;
  my (@Output);
  my (%Aux);
  my ($ret);
  my ($operatingmin);

  $Aux{'helper_top'} = {'numberproc'=>5,'magic'=>'worker|postmaster|postgres|antura'};

  $ret = helper_simplereports($Inforef, $StateRef, \@Output, ['loadaverage','df','top','ifconfig','initialize_antura'], \%Aux, \$operatingmin);

  if (defined($ret) && length($ret) > 1)
  {
    return "template_stdreporttest: helper_simplereports terminated abnormally with $ret";
  }

  # <TODO>Do something clever with operatingmin</TODO>
  if ($Inforef->{'Condition'} eq "onfailure")
  {
    my ($cmpr) = $Inforef->{'CmdLine'}->{'ConditionPercent'} || 1;

    return 1 if ($operatingmin >= $cmpr);
  }
  elsif ($Inforef->{'Condition'} eq "onsuccess")
  {
    my ($cmpr) = $Inforef->{'CmdLine'}->{'ConditionPercent'} || 0;

    return 1 if ($operatingmin <= $cmpr);
  }


  main::OutputAll($Inforef, "Standard Sample Report", \@Output);
}

1;

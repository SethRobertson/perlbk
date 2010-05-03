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

  $ret = helper_simplereports($Inforef, $StateRef, \@Output, ['loadaverage','df','top','ifconfig','linuxstats','smart'], \%Aux, \$operatingmin);

  if (defined($ret) && length($ret) > 1)
  {
    return "template_stdreporttest: helper_simplereports terminated abnormally with $ret";
  }

  main::OutputAll($Inforef, "Standard Sample Report", \@Output);
}

1;

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

  $ret = helper_simplereports($Inforef, $StateRef, \@Output, ['loadaverage','df','top','ifconfig'], \%Aux, \$operatingmin);

  if (defined($ret) && length($ret) > 1)
  {
    return "helper_simplereports terminated abnormally with $ret";
  }

  # <TODO>Do something clever with operatingmin</TODO>

  main::OutputAll($Inforef, "Standard Sample Report", \@Output);
}

1;

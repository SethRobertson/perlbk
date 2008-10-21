######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2005-2008 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
# A standard reports helper
#
# <description>Run sensor utilities reporting.</description>

sub helper_sensors($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);

  if ( -f "/etc/sensors.conf")
  {
    my $sensor = `sensors 2>&1`;

    # We don't declare errors on sensors failure
    return 1 if ($?);

    # We also don't process for voltage/fan violations.  Just record for the future.
    $Output{'name'} = "Hardware Sensor Report";
    $Output{'id'} = "sensors";
    $Output{'data'} = $sensor;
    push(@$Outputarrayref, \%Output);
  }

  1;
}

1;

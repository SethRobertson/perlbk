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
# A standard reports helper
#
# <description>Run sensor utilities reporting.</description>

sub helper_sensors($$$$)
{
  my ($Inforef, $Storedref, $Outputarrayref, $Opt) = @_;
  my (%Output);

  if ( -f "/etc/sensors.conf")
  {
    my $sensor = `sensors`;

    # We don't declare errors on sensors failure
    return 1 if ($?);

    # We also don't process for voltage/fan violations.  Just record for the future.
    $Output{'name'} = "Hardware Sensor Report";
    $Output{'data'} = $sensor;
    push(@$Outputarrayref, \%Output);
  }

  1;
}

1;

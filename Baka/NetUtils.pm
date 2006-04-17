# -*- perl -*-
# $Id: NetUtils.pm,v 1.2 2006/04/17 21:19:59 jtt Exp $
#
# ++Copyright LIBBK++
#
# Copyright (c) 2003 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Mail <projectbaka\@baka.org> for further information
#
# --Copyright LIBBK--
#


##
# @file
# Random utilities useful for dealing with networks.
#

package Baka::NetUtils;
use Exporter 'import';
@EXPORT_OK = qw (inet_atoi inet_itoa network_match network_part netmask_from_bits);


################################################################
#

# Convert an IPv4 address string into an integer. NB: using pack DOES NOT
# WORK.
#
sub inet_atoi( $)
{
  my($addr) = @_;
  my($val) = 0;
  
  my($a, $b, $c, $d) = split(/\./, $addr);

  $val = ($a<<24) | ($b<<16) | ($c<<8) | $d;
  return(($val)&0xffffffff);
}



################################################################
#
# Convert an integer into an IPv4 address string. NB: PACK DOES NOT WORK.
#
sub inet_itoa( $)
{
  my($val) = @_;

  $a = ($val>>24)&0xff;
  $b = ($val>>16)&0xff;
  $c = ($val>>8)&0xff;
  $d = $val&0xff;
  
  my($addr) = join(".", $a, $b, $c, $d);
  return($addr);
}



################################################################
#
# Check if two IPv4 addresses are on the same network.
#
sub network_match( $$$)
{
  my($addr1, $addr2, $netmask) = @_;

  my($a1) = inet_atoi($addr1);
  my($a2) = inet_atoi($addr2);
  my($n) = inet_atoi($netmask);

  return ((($a1&$n)&0xffffffff) == (($a2&$n)&0xffffffff));
}


################################################################
#
# Return the network part of an address as an IPv4 addr string.
#
sub network_part( $$)
{
  my($addr, $netmask) = @_;

  my($a) = inet_atoi($addr);
  my($n) = inet_atoi($netmask);
  my($val) = ($a&$n)&0xffffffff;

  return (inet_itoa($val));
}


################################################################
#
# Return the a netmask (as an integer) based on a bit length
#
sub netmask_from_bits($ )
{
  my($bits) = @_;

  return (-1) if (($bits < 0) || ($bits > 32));

  return ((((2**$bits)-1)<<(32-$bits))&0xffffffff);
}

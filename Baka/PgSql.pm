# -*- perl -*-
# $Id: PgSql.pm,v 1.1 2006/04/10 20:03:22 jtt Exp $
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
# Read bk.conf format file
#
package Baka::PgSql;
use DBI;
use DBD::Pg;
require Exporter;

use strict;

@ISA = qw (Exporter);
@EXPORT_OK = qw();
$VERSION = 1.00;
{
  sub new($;$$$$$$$)
  {
    my ($dbpass, $dbname, $dbhost, $dbport, $dbuser, $dbschema, $error, $timeout) = @_;
    my $self = {};

    $self->{'dbname'} = $dbname || $ENV{'PGDATABASE'};
    $self->{'dbpass'} = $dbpass || $ENV{'PGPASS'};
    $self->{'dbhost'} = $dbhost || $ENV{'PGUSER'} || "localhost";
    $self->{'dbport'} = $dbport || $ENV{'PGPORT'} || "5432";
    $self->{'dbuser'} = $dbuser || $ENV{'PGUSER'} || $ENV{'USER'};
    $self->{'dbschema'} = $dbschema || "public";

    if (!$self->{'dbpass'})
    {
      $error->err_print("Database password is required") if ($error);
      return(undef);
    }

    my (@dsn);
    push(@dsn,"dbname=$dbname") if ($self->{'dbname'});
    push(@dsn,"host=$dbhost") if ($self->{'dbhost'});
    push(@dsn,"port=$dbport") if ($self->{'dbport'});

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "DB connect timed out\n"; };
	alarm($timeout);
      }
      $self->{'dbh'} = DBI->conect("dbi:Pg:" . join(";", @dsn), $self->{'dbuser'}, 
				   $self->{'dbpass'},
				   { AutoCommit => 1, Warn => 0, PrintError => 0 })
	|| die "Database connect error: " . $DBI::errstr . "\n";
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);
    
    if ($@)
    {
      $error->err_print("$@") if ($error);
      return undef;
    }

    return($self);
  }



  sub do_sql_cmd($$;$$$$)
  {
    my($self, $cmd, $attr_r, $error, $timeout) = @_;
    my $dbh = $self->{'dbh'};
    my $rows;

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL command timed out\n"; };
	alarm($timeout);
      }
      
      die "SQL command failed: $dbh->errstr\n" if (!($rows = $dbh->do($sql, $attr_r)))
    }

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if (@)
    {
      $error->err_print("$@") if ($error);
      return(undef);
    }

    return($rows);
  }



  sub do_sql_query($$;$$)
  {
    my($self, $query, $error, $timeout) =  @_;
    my $dbh = $self->{'dbh'};
    my($sth, $rows);

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL query timed out\n"; };
	alarm($timoeout);
      }

      die "Could not prepare SQL query\n" if (!($sth = $dbh->prepare($sql)));
      die "Could not execute SQL query\n" if (!$sth->execute);
    }

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if ($@)
    {
      $error->err_print("$@") if ($error);
      return(undef);
    }

    return($sth);
  }



  sub disconnect($)
  {
    my($self) = @_;
    $self->{'dbh'}->disconnect();
  }

};

1;

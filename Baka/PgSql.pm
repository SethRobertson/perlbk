# -*- perl -*-
# $Id: PgSql.pm,v 1.4 2006/04/12 17:32:29 jtt Exp $
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
# Connect and query routines for Posgres SQL.
#
# Note the $error may be either a Baka::Error instance or IO::File handle.
#
package Baka::PgSql;
@ISA = qw (Exporter);
@EXPORT_OK = qw (sqlcmd sqlquery disconnect);
use DBI;
use DBD::Pg;
use Baka::ScriptUtils qw(berror bmsg);
{
  sub new($;$$$$$$$)
  {
    my ($type, $dbpass, $dbname, $dbhost, $dbport, $dbuser, $dbschema, $error, $timeout) = @_;

    my $self = {};
    bless $self, $type;

    $self->{'dbname'} = $dbname || $ENV{'PGDATABASE'};
    $self->{'dbpass'} = $dbpass || $ENV{'PGPASS'};
    $self->{'dbhost'} = $dbhost || $ENV{'PGUSER'} || "localhost";
    $self->{'dbport'} = $dbport || $ENV{'PGPORT'} || "5432";
    $self->{'dbuser'} = $dbuser || $ENV{'PGUSER'} || $ENV{'USER'};
    $self->{'dbschema'} = $dbschema || "public";

    if (!$self->{'dbpass'})
    {
      berror("Database password is required", $error) if ($error);
      return(undef);
    }

    my (@dsn);
    push(@dsn,"dbname=$self->{dbname}") if ($self->{'dbname'});
    push(@dsn,"host=$self->{dbhost}") if ($self->{'dbhost'});
    push(@dsn,"port=$self->{dbport}") if ($self->{'dbport'});

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "DB connect timed out\n"; };
	alarm($timeout);
      }
      $self->{'dbh'} = DBI->connect("dbi:Pg:" . join(";", @dsn), $self->{'dbuser'}, 
				    $self->{'dbpass'},
				    { AutoCommit => 1, Warn => 0, PrintError => 0 })
	|| die "Database connect error: " . $DBI::errstr . "\n";
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);
    
    if ($@)
    {
      berror("$@", $error) if ($error);
      return undef;
    }

    if ($dbschema && (!$self->sqlcmd("set search_path to $dbschema, public", undef, $error, $timeout)))
    {
      print "OK\n" if ($error);
      berror("Could not set search path to: $dbschema, public", $error) if ($error);
      $self->{'dbh'}->disconnect;
      return(undef);
    }

    return($self);
  }

  sub sqlcmd($$;$$$$)
  {
    my($self, $cmd, $error, $timeout, $attr_r) = @_;
    my $dbh = $self->{'dbh'};
    my $rows;

    bmsg("SQL Command: $cmd", $error) if ($error);

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL command timed out\n"; };
	alarm($timeout);
      }
      
      $rows = $dbh->do($cmd, $attr_r);

      die "SQL command failed: " . $dbh->errstr . "\n" if (!defined($rows));
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if ($@)
    {
      berror("$@", $error) if ($error);
      return(undef);
    }

    return($rows);
  }



  sub sqlquery($$;$$)
  {
    my($self, $sql, $error, $timeout) =  @_;
    my $dbh = $self->{'dbh'};
    my($sth, $rows);

    bmsg("SQL Query: $sql", $error) if ($error);

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL query timed out\n"; };
	alarm($timoeout);
      }

      die "Could not prepare SQL query\n" if (!($sth = $dbh->prepare($sql)));
      die "Could not execute SQL query\n" if (!$sth->execute);
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if ($@)
    {
      berror("$@", $error) if ($error);
      return(undef);
    }

    return($sth);
  }


  sub errstr($ )
  {
    my($self) = @_;
    my($dbh) = $self->{'dbh'};
    return($dbh->errstr);
  }


  sub dbh($ )
  {
    my($self) = @_;
    return($self->{'dbh'});
  }


  sub disconnect($)
  {
    my($self) = @_;
    $self->{'dbh'}->disconnect();
  }
};

1;

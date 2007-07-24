# -*- perl -*-
# $Id: PgSql.pm,v 1.6 2007/07/24 21:00:46 jtt Exp $
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
=head1 NAME

Baka::PgSql - Connect and issue commands/queries to a SQL database.

=head1 SYNOPSIS

=over 6

  use Baka::PgSql;
  
  $bdbh = Baka::PgSql->new;
  $bdbh = Baka::PgSql->new($dbpass, $dbname, $dbhost, $dbport, $dbuser, $dbschema, $berror, $timeout);
  
  $rows = $bdbh->sqlcmd($cmd, $error, $timeout, \%attr);
  $sth = $bdbh->sqlquery($query, $error, $timeout);

  $lobjid = $bdbh->lo_import($filename);
  $ret = $bdbh->lo_export($lobjid, $filename);

  $errstr = $bdbh->errstr();
  $dbh = $bdbh->dbh();
  $bdbh->disconnect();

=back

=head1 DESCRIPTION

This module provids a simple interface to perl's PgSql DBI module. It
provids convience functions for connecting, queries, commands, and large
object manipulation.

=head1 API

=over 6

=item B<new>

The constructor will make the connection to the database and all arguments
are optional. The B<db> arguments are al self-explanatory if you understand
the F<DBD::PgSql.pm> module; the constructor will use the stand PG
environment variables if any of these values are left unset. If you do not,
you should start there. B<error> is the handle returned from the
F<Baka::Error.pm> module. B<timeout> is the connection timeout; there is no
timeout by default. Multiple commands may be issued by separating them with
commas.

Returns I<bdbh> handle on success; I<undef> on failure.

=item B<sqlcmd>

This method runs a SQL command and returns the number of affected rows. The
B<cmd> is a standard SQL command (with an optional final
semicolon). B<error> and B<timeout> are just as in the constructor. The
B<attr_r> argument is a hash reference. See the F<DBI> module for more
explanation.

Returns the number of affected I<rows> on success; I<undef> on failure.

=item B<sqlquery>

The methods run a SQL command and returns the F<DBI> statment handle. The
B<query> is just a standard SQL query (iwth an optional final
semicolon). B<error> and B<timeout> as just as as in the contstructor.

Returns the F<DBI> statement handle on success; I<undef> on failure.

=item B<lo_import>

This methods imports the named F<filename> as a Postgres large object. 

Returns I<lobjid> on success; I<-1> on failure.

=item B<lo_export>

This methods imports the named F<filename> as a Postgres large object. 

Returns I<lobjid> on success; I<-1> on failure.

=item B<disconnect>

Tears down the connection to the DB.

=item B<dbh>

Returns the raw F<DBD::Pg> handle.

=item B<errstr>

Returns the current value of the F<DBD::Pg> error string.

=back

=head1 SEE ALSO

F<Baka::ScriptUtils.pm>, F<Baka::Error.pm>, F<DBI.pm>, F<DBD::Pg.pm>

=head1 AUTHOR

James Tanis

=cut

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
use strict;
{
  sub new(;$$$$$$$$)
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

    bmsg("SQL Command: $cmd: ", $error, 1) if ($error);

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL command timed out\n"; };
	alarm($timeout);
      }
      
      $rows = $dbh->do($cmd, $attr_r);

      # Do *not* use bdie here. We are inside an eval
      die "SQL command failed: " . $dbh->errstr . "\n" if (!defined($rows));
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if ($@)
    {
      berror("\nERROR: $@", $error, 0, 1) if ($error);
      return(undef);
    }

    bmsg("$rows", $error, 0, 1);

    return($rows);
  }



  sub sqlquery($$;$$)
  {
    my($self, $sql, $error, $timeout) =  @_;
    my $dbh = $self->{'dbh'};
    my($sth, $rows);

    bmsg("SQL Query: $sql: ", $error, 1) if ($error);

    eval
    {
      if ($timeout)
      {
	$SIG{'ALRM'} = sub { die "SQL query timed out\n"; };
	alarm($timeout);
      }

      # Do *not* use bdie here. We are inside an eval
      die "Could not prepare SQL query " . $dbh->errstr . "\n" if (!($sth = $dbh->prepare($sql)));
      die "Could not execute SQL query " . $dbh->errstr . "\n" if (!$sth->execute);
    };

    $SIG{'ALRM'} = 'DEFAULT' if ($timeout);

    if ($@)
    {
      berror("\nERROR: $@", $error, 0, 1) if ($error);
      return(undef);
    }

    if ($sth)
    {
      bmsg("OK", $error, 0, 1);
    }
    else
    {
      bmsg("FAILED", $error, 0, 1);
    }

    return($sth);
  }

  sub lo_import($$;$)
  {
    my($self, $filename, $error) = @_;
    my $dbh = $self->dbh();
    
    my $autocommit = $dbh->{AutoCommit};
    
    $dbh->{AutoCommit} = 0;
    my $lobjid = $dbh->func($filename, "lo_import");
    $dbh->{AutoCommit} = $autocommit;

    if (!defined($lobjid))
    {
      berror("Could not lo_import file: $filename: " . $dbh->errstr, $error) if ($error);
      return(-1);
    }
    
    return($lobjid);
  }


  sub lo_export($$$;$)
  {
    my($self, $lobjid, $filename, $error) = @_;
    my $dbh = $self->dbh();
    
    my $autocommit = $dbh->{AutoCommit};
    
    $dbh->{AutoCommit} = 0;
    my $ret = $dbh->func($lobjid, $filename, "lo_export");
    $dbh->{AutoCommit} = $autocommit;

    if (!$ret)
    {
      berror("Could not lo_export $lobjid to file: $filename: " . $dbh->errstr, $error) if ($error);
      return(-1);
    }
    
    return(0)
  }

  sub errstr($ )
  {
    my($self) = @_;
    my $dbh = $self->{'dbh'};
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

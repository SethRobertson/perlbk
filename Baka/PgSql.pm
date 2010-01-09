# -*- perl -*-
#
#
# ++Copyright BAKA++
#
# Copyright © 2006-2010 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
=head1 NAME

Baka::PgSql - Connect and issue commands/queries to a SQL database.

=head1 SYNOPSIS

=over 6

  use Baka::PgSql;

  $bdbh = Baka::PgSql->new;
  $bdbh = Baka::PgSql->new($dbpass, $dbname, $dbhost, $dbport, $dbuser, $dbschema, $berror, $timeout);

  $rows = $bdbh->sqlcmd($cmd, $timeout, \%attr);
  $sth = $bdbh->sqlquery($query, $timeout);

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
  sub new()
  {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($dbpass, $dbname, $dbhost, $dbport, $dbuser, $dbschema, $error, $timeout);
    my $old_alarm_handler;
    my $decrypt_password = 1;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    if (my $config = $args{'config'})
    {

      # Obtain default values from the config file. Note these will be
      # overridden by specific hashref entries of the same name (ie see
      # the for loop below.
      $dbhost = $config->get("postgres_host");
      $dbuser = $config->get("postgres_user");
      $dbport = $config->get("postgres_port");
      $dbpass = $config->get("postgres_password");
      $dbname = $config->get("postgres_dbname");
      $dbschema = $config->get("postgres_schema");
    }

    foreach my $name ('dbpass', 'dbname', 'dbhost', 'dbport', 'dbuser', 'dbschema', 'error', 'timeout', 'decrypt_passwd')
    {
      eval "\$$name = \$args{$name}" if (defined($args{$name}));
    }

    $self->{'dbname'} = $dbname || $ENV{'PGDATABASE'};
    $self->{'dbpass'} = $dbpass || $ENV{'PGPASSWORD'};
    $self->{'dbhost'} = $dbhost || $ENV{'PGHOST'} || "localhost";
    $self->{'dbport'} = $dbport || $ENV{'PGPORT'} || "5432";
    $self->{'dbuser'} = $dbuser || $ENV{'PGUSER'} || $ENV{'USER'};
    $self->{'dbschema'} = $dbschema || "public";
    $self->{'error'} = $error;

    if (!$self->{'dbpass'})
    {
      berror("Database password is required", $self->{'error'}) if ($self->{'error'});
      return(undef);
    }

    $self->{'dbpass'} = de_vigenere(0, $self->{'dbpass'}) if ($decrypt_password);

    bmsg("DB Connect: $self->{'dbhost'}:$self->{'dbport'}, DB: $self->{'dbname'}, User: $self->{'dbuser'}, Schema: $self->{'dbschema'}\n", $self->{'error'}) if ($self->{'error'});

    my @dsn;
    push(@dsn,"dbname=$self->{dbname}") if ($self->{'dbname'});
    push(@dsn,"host=$self->{dbhost}") if ($self->{'dbhost'});
    push(@dsn,"port=$self->{dbport}") if ($self->{'dbport'});

    if ($timeout)
    {
      # In all the routines that follow there is always a race condition
      # between the time the DB action finishes and when alarm(0) runs. Thus,
      # instead of cheating the caller out of a little bit of time, we give
      # him plenty more than actually asked for -- or at least we *hope*
      # so. In theory it could take longer than one second to run alarm(0).
      $timeout++;
      $old_alarm_handler = $SIG{'ALRM'} || 'DEFAULT';
      $SIG{'ALRM'} = sub { die "DB connect timed out\n"; }; # die is OK because of eval
      alarm($timeout);
    }

    eval
    {
      $self->{'dbh'} = DBI->connect("dbi:Pg:" . join(";", @dsn), $self->{'dbuser'},
				    $self->{'dbpass'},
				    { AutoCommit => 1, Warn => 0, PrintError => 0 })
	|| die "Database connect error: " . $DBI::errstr . "\n";
    };

    if ($timeout)
    {
      alarm(0);
      $SIG{'ALRM'} = $old_alarm_handler;
    }

    if ($@)
    {
      berror("$@", $self->{'error'}) if ($self->{'error'});
      return undef;
    }

    if ($dbschema && (!defined($self->sqlcmd("set search_path to $dbschema, public", $timeout))))
    {
      berror("Could not set search path to: $dbschema, public", $self->{'error'}) if ($self->{'error'});
      $self->{'dbh'}->disconnect;
      return(undef);
    }

    return($self);
  }

  sub sqlcmd($$;$$)
  {
    my($self, $cmd, $timeout, $attr_r) = @_;
    my $dbh = $self->{'dbh'};
    my $rows;
    my $old_alarm_handler;

    bmsg("SQL Command: $cmd: ", $self->{'error'}, 1) if ($self->{'error'});

    if ($timeout)
    {
      $timeout++; # See race condition remark in the constructor function
      $old_alarm_handler = $SIG{'ALRM'} || "DEFAULT";
      $SIG{'ALRM'} = sub { die "SQL command timed out\n"; };
      alarm($timeout);
    }
    eval
    {
      $rows = $dbh->do($cmd, $attr_r);
      # Do *not* use bdie here. We are inside an eval
      die "SQL command failed: " . $dbh->errstr . "\n" if (!defined($rows));
    };

    if ($timeout)
    {
      alarm(0);
      $SIG{'ALRM'} = $old_alarm_handler;
    }

    if ($@)
    {
      berror("\nERROR: $@", $self->{'error'}, 0, 1) if ($self->{'error'});
      return(undef);
    }

    bmsg("$rows", $self->{'error'}, 0, 1);

    return($rows);
  }



  sub sqlquery($$;$)
  {
    my($self, $sql, $timeout) =  @_;
    my $dbh = $self->{'dbh'};
    my($sth, $rows, $old_alarm_handler);

    bmsg("SQL Query: $sql: ", $self->{'error'}, 1) if ($self->{'error'});

    if ($timeout)
    {
      $timeout++; # See race condition remark in constructor function
      $old_alarm_handler = $SIG{'ALRM'} || "DEFAULT";
      $SIG{'ALRM'} = sub { die "SQL query timed out\n"; };
      alarm($timeout);
    }

    eval
    {
      # Do *not* use bdie here. We are inside an eval
      die "Could not prepare SQL query " . $dbh->errstr . "\n" if (!($sth = $dbh->prepare($sql)));
      die "Could not execute SQL query " . $dbh->errstr . "\n" if (!$sth->execute);
    };

    if ($timeout)
    {
      alarm(0);
      $SIG{'ALRM'} = $old_alarm_handler;
    }

    if ($@)
    {
      berror("\nERROR: $@", $self->{'error'}, 0, 1) if ($self->{'error'});
      return(undef);
    }

    if ($sth)
    {
      bmsg("OK", $self->{'error'}, 0, 1);
    }
    else
    {
      bmsg("FAILED", $self->{'error'}, 0, 1);
    }

    return($sth);
  }

  sub lo_import($$)
  {
    my($self, $filename) = @_;
    my $dbh = $self->dbh();

    my $autocommit = $dbh->{AutoCommit};

    $dbh->{AutoCommit} = 0;
    my $lobjid = $dbh->func($filename, "lo_import");
    $dbh->{AutoCommit} = $autocommit;

    if (!defined($lobjid))
    {
      berror("Could not lo_import file: $filename: " . $dbh->errstr, $self->{'error'}) if ($self->{'error'});
      return(-1);
    }

    return($lobjid);
  }


  sub lo_export($$$)
  {
    my($self, $lobjid, $filename) = @_;
    my $dbh = $self->dbh();

    my $autocommit = $dbh->{AutoCommit};

    $dbh->{AutoCommit} = 0;
    my $ret = $dbh->func($lobjid, $filename, "lo_export");
    $dbh->{AutoCommit} = $autocommit;

    if (!$ret)
    {
      berror("Could not lo_export $lobjid to file: $filename: " . $dbh->errstr, $self->{'error'}) if ($self->{'error'});
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


  sub disconnect($ )
  {
    my($self) = @_;
    $self->{'dbh'}->disconnect();
  }

  sub de_vigenere($$;$ )
  {
    my ($encrypt,$in,$pass) = @_;
    my ($out);

    if (!defined($in))
    {
      return $in;
    }

    $pass = "fi5tRkH4Jh87o2Bo<--This is not providing a lot of security" unless ($pass);
    my ($plen) = length($pass);
    my (@pass) = split(//,$pass);
    my $printable = "O.Y;0>mM/f(2-qxclkAvRJ\@ PU}5WgX)#N\\!\${9B`Knh_]7<rs?+uH:'e1,6LpD~=aETd4j8wo\"\%[Gyb*FQztZC|ISV^i3\&";
    my $printablelen = length($printable);

    my $length = length($in);
    for(my $x = 0;$x < $length; $x++)
    {
      my $c = substr($in,$x,1);
      my $loc = index($printable,$c);

      # We only ``encrypt'' printable characters
      if ($loc >= 0)
      {
	if ($encrypt)
	{
	  $loc += index($printable,$pass[$x%$plen]);
	}
	else
	{
	  $loc -= index($printable,$pass[$x%$plen]);
	}
	$out .= substr($printable,$loc % $printablelen,1);
      }
      else
      {
	$out .= $c;
      }
    }
    $out;
  }

  sub quote($ )
  {
    my($self, $str) = @_;

    $str =~ s/\\/\\\\/g;
    $str =~ s/\'/\\\'/g;
    return("E'$str'");
  }

};

1;

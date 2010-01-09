######################################################################
#
# ++Copyright BAKA++
#
# Copyright © 2003-2010 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
#
# Perl utilities Makefile
#

BK_PERL_MODS=			\
	Baka/Conf.pm		\
	Baka/Error.pm		\
	Baka/Exception.pm	\
	Baka/NetUtils.pm	\
	Baka/PgSql.pm		\
	Baka/ScriptUtils.pm	\
	Baka/SendRecv.pm	\
	Baka/StructuredConf.pm	\
# Line eater fodder

BK_SUBDIR=bin perl/BkReportGen lib

GROUPTOP=..
GROUPSUBDIR=perlbk


##################################################
## BEGIN BKSTANDARD MAKEFILE
-include ./Make.preinclude
-include $(GROUPTOP)/Make.preinclude
-include $(GROUPTOP)/$(PKGTOP)/Make.preinclude
include $(GROUPTOP)/$(PKGTOP)/bkmk/Make.include
-include $(GROUPTOP)/$(PKGTOP)/Make.include
-include $(GROUPTOP)/Make.include
-include ./Make.include
## END BKSTANDARD MAKEFILE
##################################################

actual_install::
	@perl -MLog::Dispatch -e 1 >/dev/null 2>&1 || echo '*** Warning: Missing Log::Dispatch module for Baka::Error ***'
	@perl -MDBD::Pg -e 1 >/dev/null 2>&1 || echo '*** Warning: Missing optional DBD::Pg module for Baka::PgSql ***'


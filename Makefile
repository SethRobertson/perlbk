######################################################################
#
# ++Copyright LIBBK++
#
# Copyright (c) 2003 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Mail <projectbaka@baka.org> for further information
#
# --Copyright LIBBK--
#
#
# Perl utilities Makefile
#

BK_PERL_MODS=			\
	Baka/Conf.pm		\
	Baka/Error.pm		\
	Baka/Exception.pm	\
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

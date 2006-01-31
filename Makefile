######################################################################
# $Id: Makefile,v 1.10 2006/01/31 09:22:24 jtt Exp $
#
# ++Copyright SYSDETECT++
#
# Copyright (c) 2001 System Detection.  All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SYSTEM DETECTION.
# The copyright notice above does not evidence any actual
# or intended publication of such source code.
#
# Only properly authorized employees and contractors of System Detection
# are authorized to view, posses, to otherwise use this file.
#
# System Detection
# 5 West 19th Floor 2 Suite K
# New York, NY 10011-4240
#
# +1 212 242 2970
# <sysdetect@sysdetect.org>
#
# --Copyright SYSDETECT--
#
# Perl utilities Makefile
#

BK_PERL_MODS=			\
	Baka/Error.pm		\
	Baka/Exception.pm	\
	Baka/Conf.pm		\
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


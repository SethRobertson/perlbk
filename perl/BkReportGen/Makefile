######################################################################
# $Id: Makefile,v 1.1 2004/02/17 03:24:27 seth Exp $
#
# ++Copyright SYSDETECT++
#
# Copyright (c) 2003 System Detection.  All rights reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF SYSTEM DETECTION.
# The copyright notice above does not evidence any actual
# or intended publication of such source code.
#
# Only properly authorized employees and contractors of System Detection
# are authorized to view, possess, to otherwise use this file.
#
# System Detection
# 5 West 19th Street Floor 2K
# New York, NY 10011-4240
#
# +1 212 206 1900
# <support@sysd.com>
#
# --Copyright SYSDETECT--
#
# Perl utility programs Makefile
#

MODULES=			\
	output_stdout.pl	\
	template_helloworld.pl	\
# Line eater fodder -- do no remove

GROUPTOP=../../..
GROUPSUBDIR=perlbk/perl/BkReportGen
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

actual_install install::
	$(MKDIR) $(BK_INSTALLPERLDIR)/BkReportGen $(BK_INSTALLPERLDIR)/../var/BkReportGen
	$(INSTALL) $(INSTALL_OTHERFLAGS) $(MODULES) $(BK_INSTALLPERLDIR)/BkReportGen

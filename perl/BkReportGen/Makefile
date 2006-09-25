######################################################################
# $Id: Makefile,v 1.11 2006/09/25 18:39:25 seth Exp $
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

MODULES=					\
	helper_df.pl				\
	helper_health_include.pl		\
	helper_ifconfig.pl			\
	helper_linuxstats.pl			\
	helper_loadaverage.pl			\
	helper_mce.pl				\
	helper_raid.pl				\
	helper_sensors.pl			\
	helper_simplereports.pl			\
	helper_smart.pl				\
	helper_top.pl				\
	output_exec.pl				\
	output_file.pl				\
	output_mailto.pl			\
	output_postgres.pl			\
	output_stdout.pl			\
	template_helloworld.pl			\
	template_stdreporttest.pl		\
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

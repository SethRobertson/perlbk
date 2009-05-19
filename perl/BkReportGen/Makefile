######################################################################
#
#
#
# ++Copyright BAKA++
#
# Copyright © 2004-2008 The Authors. All rights reserved.
#
# This source code is licensed to you under the terms of the file
# LICENSE.TXT in this release for further details.
#
# Send e-mail to <projectbaka@baka.org> for further information.
#
# - -Copyright BAKA- -
#
#
# Perl utility programs Makefile
#

MODULES=					\
	helper_bmc.pl				\
	helper_df.pl				\
	helper_edac.pl				\
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
	output_directory.pl			\
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

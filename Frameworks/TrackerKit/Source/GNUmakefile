#
#	GNUmakefile
#
#	Makefile for TrackerKit
#
#	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
#
#	This Makefile is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License
#	as published by the Free Software Foundation; either version 2
#	of the License, or (at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#	See the GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to:
#
#		Free Software Foundation, Inc.
#		59 Temple Place - Suite 330
#		Boston, MA  02111-1307, USA
#

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
LIBRARY_NAME=		libTrackerKit	
VERSION=		0.1

#
# Resource files
#
libTrackerKit_MAIN_MODEL_FILE=

libTrackerKit_RESOURCE_FILES=

libTrackerKit_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
libTrackerKit_LANGUAGES= \
	English
	
#
# Class files
#
libTrackerKit_OBJC_FILES= \
	TKQuery.m \
	TKStructuralKey.m \
	TKTracker.m 
#
# C files
#
libTrackerKit_C_FILES=

#
# Header files
#
libTrackerKit_HEADER_FILES_DIR = ../Headers

libTrackerKit_HEADER_FILES_INSTALL_DIR = /TrackerKit

libTrackerKit_HEADER_FILES = \
	TKQuery.h \
	TKStructuralKey.h \
	TKTracker.h 
	
-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

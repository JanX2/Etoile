#
#	GNUmakefile
#
#	Makefile for ServicesBarKit
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

ADDITIONAL_OBJCFLAGS += -Wno-import

#
# Main application
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

PACKAGE_NAME = ServicesBarKit	
ifeq ($(test), yes)
BUNDLE_NAME = libServicesBarKit
ADDITIONAL_LDFLAGS = -lUnitKit -lgnustep-gui -lgnustep-base
else
LIBRARY_NAME = libServicesBarKit
endif
VERSION = 0.1

libServicesBarKit_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)

#
# Resource files
#
libServicesBarKit_MAIN_MODEL_FILE =
libServicesBarKit_RESOURCE_FILES =

libServicesBarKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
libServicesBarKit_LANGUAGES = \
	English

#
# Header files
#
libServicesBarKit_HEADERS = \
	SBServicesBarItem.h \
	SBServicesBar.h
	
ifeq ($(test), no)
libServicesBarKit_HEADER_FILES_INSTALL_DIR = /ServicesBarKit
endif


#
# Class files
#
libServicesBarKit_OBJC_FILES = \
	SBServicesBarItem.m \
	SBServicesBar.m

#
# C files
#
libServicesBarKit_C_FILES = 

-include GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include GNUmakefile.postamble

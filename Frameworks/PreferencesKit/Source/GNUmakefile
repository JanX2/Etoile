#
#	GNUmakefile
#
#	Makefile for Etoile PreferencesKit
#
#	Copyright (C) 2005 Quentin Mathe <qmathe@club-internet.fr>
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

ADDITIONAL_INCLUDE_DIRS = -I../Headers

#
# Main application
#
LIBRARY_NAME=		libPreferencesKit
VERSION=		0.1

#
# Resource files
#
libPreferencesKit_MAIN_MODEL_FILE=

libPreferencesKit_RESOURCE_FILES=

libPreferencesKit_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
libPreferencesKit_LANGUAGES= \
	English
	
#
# Class files
#
libPreferencesKit_OBJC_FILES= \
	PKApplicationController.m \
	PKBundleController.m \
	PKPreferencesController.m \
	PKPreferencePane.m \
	PKTableViewPreferencesController.m \
	PKToolbarPreferencesController.m \

#
# Header files
#
libPreferencesKit_HEADER_FILES = \
	PreferencePane.h \
	PKApplicationController.h \
	PKBundleController.h \
	PKPreferencesController.h \
	PKPreferencePane.h \
	PKTableViewPreferencesController.h \
	PKToolbarPreferencesController.h

libPreferencesKit_HEADER_FILES_DIR = ../Headers

libPreferencesKit_HEADER_FILES_INSTALL_DIR = /PreferencesKit

libPreferencesKit_HEADER_INSTALL = \
	PreferencePane.h \
	PKApplicationController.h \
	PKBundleController.h \
	PKPreferencesController.h \
	PKPreferencePane.h \
	PKTableViewPreferencesController.h \
	PKToolbarPreferencesController.h

#
# C files
#
libPreferencesKit_C_FILES=

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

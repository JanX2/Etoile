#
#	GNUmakefile
#
#	Makefile for Etoile PreferencesKitExample
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

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

PACKAGE_NAME = SamplePrefsModule.prefsModule

#
# Main application
#
BUNDLE_NAME = SamplePrefsModule
VERSION = 0.1
BUNDLE_EXTENSION = .prefsModule
BUNDLE_INSTALL_DIR = 

SamplePrefsModule_PRINCIPAL_CLASS = SamplePrefsModule
SamplePrefsModule_APPLICATION_ICON =

SamplePrefsModule_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
SamplePrefsModule_MAIN_MODEL_FILE = \
	SamplePrefsModule.gorm

SamplePrefsModule_RESOURCE_FILES = \
	SamplePrefsModule.gorm \
	Preferences.tiff \
	SamplePrefsModuleInfo.plist

SamplePrefsModule_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
SamplePrefsModule_LANGUAGES = \
	English
	
#
# Class files
#
SamplePrefsModule_OBJC_FILES = \
	SamplePrefsModule.m

#
# Header files
#
SamplePrefsModule_HEADER_FILES = \
	SamplePrefsModule.h

#
# C files
#
SamplePrefsModule_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

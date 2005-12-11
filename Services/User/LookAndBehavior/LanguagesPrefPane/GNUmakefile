#
#	GNUmakefile
#
#	Makefile for Etoile LanguagesPrefPane
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

#
# Main application
#
BUNDLE_NAME = LanguagesPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane
BUNDLE_INSTALL_DIR = 

LanguagesPrefPane_PRINCIPAL_CLASS = LanguagesPrefPane
LanguagesPrefPane_APPLICATION_ICON =

LanguagesPrefPane_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
LanguagesPrefPane_MAIN_MODEL_FILE = \
	Languages.gorm

LanguagesPrefPane_RESOURCE_FILES = \
	Languages.gorm \
	LanguagesPrefPaneIcon.tiff \
	LanguagesPrefPaneInfo.plist

LanguagesPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
LanguagesPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
LanguagesPrefPane_OBJC_FILES = \
	LanguagesPrefPane.m

#
# Header files
#
LanguagesPrefPane_HEADER_FILES = \
	LanguagesPrefPane.h

#
# C files
#
LanguagesPrefPane_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

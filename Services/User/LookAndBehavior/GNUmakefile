#
#	GNUmakefile
#
#	Makefile for Etoile LookAndBehavior
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

PACKAGE_NAME = LookAndBehavior

SUBPROJECTS = AppearancePrefPane LanguagesPrefPane

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

ADDITIONAL_INSTALL_DIRS = PlugIns

#
# Main application
#
APP_NAME = LookAndBehavior
VERSION = 0.1

LookAndBehavior_PRINCIPAL_CLASS = NSApplication
LookAndBehavior_APPLICATION_ICON =

LookAndBehavior_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
LookAndBehavior_MAIN_MODEL_FILE = \
	MainMenu.gorm

LookAndBehavior_RESOURCE_FILES = \
	LookAndBehaviorInfo.plist \
	MainMenu.gorm

LookAndBehavior_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
LookAndBehavior_LANGUAGES = \
	English

#
# Class files
#
LookAndBehavior_OBJC_FILES = \
	main.m

#
# Header files
#
LookAndBehavior_HEADER_FILES =

#
# C files
#
LookAndBehavior_C_FILES =


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble

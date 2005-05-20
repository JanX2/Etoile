#
#	GNUmakefile
#
#	Makefile for UKDistributedViewExample
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

ADDITIONAL_INCLUDE_DIRS = \
	-I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

PACKAGE_NAME = DistributedViewExample

#
# Main application
#	
APP_NAME = DistributedViewExample
VERSION = 0.1

DistributedViewExample_PRINCIPAL_CLASS = NSApplication
DistributedViewExample_APPLICATION_ICON =

DistributedViewExample_GUI_LIBS = -lEtoileExtensions

#
# Resource files
#
DistributedViewExample_MAIN_MODEL_FILE = MainMenu.gorm
DistributedViewExample_RESOURCE_FILES = \
	DistributedViewExampleInfo.plist \
	MainMenu.gorm \
	LadyJayeIcon.tiff \
	MediDoc.tiff \
	MimiRogersIcon.tiff

DistributedViewExample_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
DistributedViewExample_LANGUAGES = \
	English

#
# Header files
#
DistributedViewExample_HEADER_FILES_DIR = .

DistributedViewExample_HEADERS = \
	MyDataSource.h \
	MyDistViewItem.h

#
# Class files
#
DistributedViewExample_OBJC_FILES = \
	MyDataSource.m \
	MyDistViewItem.m \
	main.m

#
# C files
#
DistributedViewExample_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

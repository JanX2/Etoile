#
#	GNUmakefile
#
#	Main makefile for Etoile Workspace Filie Core
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

ADDITIONAL_INCLUDE_DIRS = \
	-I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

#
# Main application
#
SUBPROJECT_NAME = FilieCore
VERSION=		0.1

#
# Resource files
#
FilieCore_RESOURCE_FILES= 

FilieCore_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
FilieCore_LANGUAGES= \
	English

#
# Header files
#
FilieCore_HEADERS= \
        Cocoa.h \
        UKFileInfoMixedValueIndicator.h \
	UKFileInfoPanel.h \
	UKFileInfoProtocol.h \
	UKFolderDataSource.h \
	UKFolderIconViewController.m \
	UKFolderMetaStorage.h \
	UKFSDataSourceProtocol.h \
	UKFSItemViewProtocol.h \
	UKFSItem.h \
	UKMainThreadActionQueue.h \

#
# Class files
#
FilieCore_OBJC_FILES= \
	UKFileInfoMixedValueIndicator.m \
	UKFileInfoPanel.m \
	UKFolderDataSource.m \
        UKFolderIconViewController.m \
	UKFolderMetaStorage.m \
        UKFSItem.m \
	UKMainThreadActionQueue.m

#
# C files
#
FilieCore_C_FILES=

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

#
#	GNUmakefile
#
#	Makefile for ExtendedWorkspaceKit
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

ADDITIONAL_INCLUDE_DIRS = -I../Headers -I/sw/include/glib-2.0 \
-I/sw/lib/glib-2.0/include -I/sw/include/gnome-vfs-2.0 
ADDITIONAL_LIB_DIRS = -L/sw/lib
ADDITIONAL_DEPENDS = -lglib -lgnomevfs

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
LIBRARY_NAME=		libExtendedWorkspace	
VERSION=		0.1

FRAMEWORKS= # TrackerKit

#
# Resource files
#
libExtendedWorkspace_MAIN_MODEL_FILE=

libExtendedWorkspace_RESOURCE_FILES=

libExtendedWorkspace_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
libExtendedWorkspace_LANGUAGES= \
	English
	
#
# Class files
#
libExtendedWorkspace_OBJC_FILES= \
	EXTAttribute.m \
	EXTBasicFSAttributesExtracter.m \
	EXTContext.m \
	EXTFileManager.m \
	EXTGNOMEVFS.m \
	EXTGNUstepVFS.m \
	EXTLibFerrisVFS.m \
	EXTVFS.m \
	EXTVFSBack.m \
	EXTWorkspace.m \
	NSURL+ExtendedWorkspace.m
	
	# EXTDataCruxWorkspace.m \
	# EXTEXIFAttributesExtracter.m \
	# EXTExtendedFSAttributesExtracter.m \
	# EXTExtensionsProtocols.m

	# EXTLibFerrisWorkspace.m \
	# EXTPresentationAttribute.m \
	# EXTPreviewAttribute.m \
	# EXTQuery.m \
	# EXTTypeAttribute.m

	# EXTXMLAttributesExtracter.m

#
# C files
#
libExtendedWorkspace_C_FILES=

#
# Header files
#
libExtendedWorkspace_HEADER_FILES_DIR = ../Headers

libExtendedWorkspace_HEADER_FILES_INSTALL_DIR = /ExtendedWorkspaceKit

libExtendedWorkspace_HEADER_FILES = \
    ExtendedWorkspaceKit.h \
	EXTAttribute.h \
	EXTBasicFSAttributesExtracter.h \
	EXTContext.h \
	EXTDataCruxWorkspace.h \
	EXTEXIFAttributesExtracter.h \
	EXTExtendedFSAttributesExtracter.h \
	EXTFileManager.h \
	EXTGNOMEVFS.h \
	EXTGNUstepVFS.h \
	EXTLibFerrisVFS.h \
	EXTLibFerrisWorkspace.h \
	EXTLibFerrisWorkspace.h \
	EXTPresentationAttribute.h \
	EXTPreviewAttribute.h \
	EXTQuery.h \
	EXTTypeAttribute.h \
	EXTVFS.h \
	EXTVFSBack.h \
	EXTWorkspace.h \
	EXTXMLAttributesExtracter.h \
	NSURL+ExtendedWorkspace.h
	
    # EXTExtensionsProtocols.h
	
-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

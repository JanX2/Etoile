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

ADDITIONAL_INCLUDE_DIRS = -I../Headers
ADDITIONAL_LIB_DIRS = 
ADDITIONAL_DEPENDS = 

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
	EXAttribute.m \
	EXAttributesCore.m \
	EXBasicFSAttributesExtracter.m \
	EXContext.m \
	EXFileManager.m \
	EXGNUstepVFS.m \
	EXRDFAttributesCore.m \
	EXSearchCore.m \
	EXVFS.m \
	EXVFSBack.m \
	EXVFSHandle.m \
	EXWorkspace.m \
	NSURL+ExtendedWorkspace.m
	
	# EXEXIFAttributesExtracter.m \
	# EXExtendedFSAttributesExtracter.m \
	# EXExtensionsProtocols.m

	# EXPresentationAttribute.m \
	# EXPreviewAttribute.m \
	# EXQuery.m \
	# EXTypeAttribute.m

	# EXXMLAttributesExtracter.m

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
	EXAttribute.h \
	EXAttributesCore.h \
	EXBasicFSAttributesExtracter.h \
	EXContext.h \
	EXEXIFAttributesExtracter.h \
	EXExtendedFSAttributesExtracter.h \
	EXFileManager.h \
	EXGNUstepVFS.h \
	EXPresentationAttribute.h \
	EXPreviewAttribute.h \
	EXQuery.h \
	EXRDFAttributesCore.h \
	EXSearchCore.h \
	EXTypeAttribute.h \
	EXVFS.h \
	EXVFSBack.h \
	EXVFSHandle.h \
	EXWorkspace.h \
	EXXMLAttributesExtracter.h \
	NSURL+ExtendedWorkspace.h \
	EXExtensionProtocols.h 
	
HEADERS_INSTALL = \
    	ExtendedWorkspaceKit.h \
	EXAttribute.h \
	EXContext.h \
	EXFileManager.h \
	EXPresentationAttribute.h \
	EXPreviewAttribute.h \
	EXQuery.h \
	EXSearchCore.h \
	EXTypeAttribute.h \
	EXVFS.h \
	EXVFSHandle.h \
	EXWorkspace.h \
	NSURL+ExtendedWorkspace.h 
	

	
-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

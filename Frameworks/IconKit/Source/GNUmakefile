#
#	GNUmakefile
#
#	Makefile for IconKit
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

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
LIBRARY_NAME = libIconKit	
VERSION = 0.1

#
# Resource files
#
libIconKit_MAIN_MODEL_FILE =

libIconKit_RESOURCE_FILES =

libIconKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
libIconKit_LANGUAGES= \
	English
		
#
# Class files
#
libIconKit_OBJC_FILES= \
	IKCompositorOperation.m \
	IKCompositor.m \
	IKIcon.m \
	IKIconProvider.m \
	IKApplicationIconProvider.m \
	IKWorkspaceAdditions.m \
	NSFileManager+IconKit.m \
	NSString+MD5Hash.m
	
#
# C files
#
libIconKit_C_FILES =

#
# Header files
#
libIconKit_HEADER_FILES_DIR = ../Headers

libIconKit_HEADERS = \
	IKIcon.h \
	IKCompositorOperation.h \
	IKCompositor.h \
	IKIconIdentifier.h \
	IKIconPositions.h \
	IKIconProvider.h \
	IKApplicationIconProvider.h \
	IKWorkspaceAdditions.h \
	NSFileManager+IconKit.h \
	NSString+MD5Hash.h

libIconKit_HEADER_FILES_INSTALL_DIR = /IconKit

libIconKit_HEADER_FILES = \
	IconKit.h \
	IKCompositorOperation.h \
	IKCompositor.h \
	IKIcon.h \
	IKIconIdentifier.h \
	IKIconPositions.h \
	IKIconProvider.h \
	IKApplicationIconProvider.h \
	IKWorkspaceAdditions.h	
	
-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

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

ADDITIONAL_OBJCFLAGS += -Wno-import
# The last flag is to include the headers directory named IconKit and created 
# by etoile.make
ADDITIONAL_INCLUDE_DIRS += -I../Headers -I..

# If we decide to move away from truncf as a GCC builtin function, it will be
# mandatory to link C math lib.
# ADDITIONAL_LDFLAGS = -lm 

#
# Main application
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

PACKAGE_NAME = IconKit
ifeq ($(test), yes)
BUNDLE_NAME = libIconKit
ADDITIONAL_LDFLAGS += -lUnitKit -lgnustep-gui -lgnustep-base
ADDITIONAL_CFLAGS += -DHAVE_UKTEST
else
LIBRARY_NAME = libIconKit	
endif
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
	IKThumbnailProvider.m \
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

ifneq ($(test), yes)
libIconKit_HEADER_FILES_INSTALL_DIR = IconKit

libIconKit_HEADER_FILES = \
	IconKit.h \
	IKCompositorOperation.h \
	IKCompositor.h \
	IKIcon.h \
	IKIconIdentifier.h \
	IKIconPositions.h \
	IKIconProvider.h \
	IKThumbnailProvider.h \
	IKApplicationIconProvider.h \
	IKWorkspaceAdditions.h	
endif
	
-include ../GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include ../GNUmakefile.postamble

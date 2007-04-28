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

ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS += -Wno-import
# The last flag is to include the headers directory named IconKit and created 
# by etoile.make
ADDITIONAL_INCLUDE_DIRS += -I../Headers -I..

# If we decide to move away from truncf as a GCC builtin function, it will be
# mandatory to link C math lib.
# ADDITIONAL_LDFLAGS = -lm 

#
# Main library
#

PACKAGE_NAME = IconKit
ifeq ($(test), yes)
BUNDLE_NAME = IconKit
ADDITIONAL_LDFLAGS += -lUnitKit -lgnustep-gui -lgnustep-base
ADDITIONAL_CFLAGS += -DHAVE_UKTEST
else
FRAMEWORK_NAME = IconKit	
endif
VERSION = 0.1

#
# Resource files
#
IconKit_MAIN_MODEL_FILE =

IconKit_RESOURCE_FILES = ../GNUstep.icontheme

IconKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
IconKit_LANGUAGES= \
	English
		
#
# Class files
#
IconKit_OBJC_FILES= \
	IKCompositorOperation.m \
	IKCompositor.m \
	IKIcon.m \
	IKIconTheme.m \
	IKIconProvider.m \
	IKApplicationIconProvider.m \
	IKThumbnailProvider.m \
	IKWorkspaceAdditions.m \
	NSFileManager+IconKit.m \
	NSString+MD5Hash.m
	
#
# C files
#
IconKit_C_FILES =

#
# Header files
#
IconKit_HEADER_FILES_DIR = ../Headers

ifneq ($(test), yes)
IconKit_HEADER_FILES_INSTALL_DIR = IconKit

IconKit_HEADER_FILES = \
	IconKit.h \
	IKCompositorOperation.h \
	IKCompositor.h \
	IKIcon.h \
	IKIconTheme.h \
	IKIconIdentifier.h \
	IKIconPositions.h \
	IKIconProvider.h \
	IKThumbnailProvider.h \
	IKApplicationIconProvider.h \
	IKWorkspaceAdditions.h	
endif

-include ../GNUmakefile.preamble

# NOTE: Include etoile.make include before framework.make otherwise the
# compilation may fail if you type 'make; make' (see bug #8806).
include ../../../etoile.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include ../GNUmakefile.postamble

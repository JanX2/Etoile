#
#	GNUmakefile
#
#	Makefile for BookmarkKit
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
LIBRARY_NAME = libBookmarkKit	
VERSION = 0.1

#
# Resource files
#
libBookmarkKit_MAIN_MODEL_FILE =

libBookmarkKit_RESOURCE_FILES =

libBookmarkKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
libBookmarkKit_LANGUAGES = \
	English
	
#
# Class files
#
libBookmarkKit_OBJC_FILES = \
    BKBookmark.m \
    BKBookmarkQuery.m \
    BKBookmarkSearchResult.m \
	BKBookmarkStore.m
	
#
# C files
#
libBookmarkKit_C_FILES=

#
# Header files
#
libBookmarkKit_HEADER_FILES_DIR = ../Headers

libBookmarkKit_HEADER_FILES_INSTALL_DIR = /BookmarkKit

libBookmarkKit_HEADER_FILES = \
    BKBookmark.h \
    BKBookmarkQuery.h \
    BKBookmarkSearchResult.h \
    BKBookmarkStore.h
	
-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble

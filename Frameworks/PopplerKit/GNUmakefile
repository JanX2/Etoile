#
# GNUmakefile
#
# Compile the PopplerKit Framework (part of ImageKits).
#
# Copyright (C) 2005 Stefan Kleine Stegemann <stefan@wms-network.de>
#
# This Makefile is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See the GNU General Public License for more details.
#

include $(GNUSTEP_MAKEFILES)/common.make

-include config.make

FRAMEWORK_NAME                         = PopplerKit
PopplerKit_CURRENT_VERSION_NAME        = 1.0
PopplerKit_DEPLOY_WITH_CURRENT_VERSION = yes

PopplerKit_SUBPROJECTS = \
bindings \
MissingKit

PopplerKit_HEADER_FILES = \
PopplerCairoImageRenderer.h \
PopplerDirectBufferedRenderer.h \
PopplerDocument.h \
PopplerFontManager.h \
PopplerKit.h \
PopplerPage.h \
PopplerTextHit.h \
PopplerRenderer.h \
PopplerTextSearch.h \
PopplerSplashRenderer.h \
PopplerCachingRenderer.h \
PopplerDocument+Rendering.h

PopplerKit_OBJC_FILES = \
CountingRef.m \
NSBitmapImageRep+LRUCache.m \
NSString+PopplerKitAdditions.m \
PopplerCairoImageRenderer.m \
PopplerDirectBufferedRenderer.m \
PopplerDocument.m \
PopplerDocument+Rendering.m \
PopplerFontManager.m \
PopplerPage.m \
PopplerTextHit.m \
PopplerTextSearch.m \
PopplerSplashRenderer.m \
PopplerCachingRenderer.m \
PopplerKitFunctions.m

PopplerKit_RESOURCE_FILES = \
	Fonts/*


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import -DGNUSTEP
ADDITIONAL_INCLUDE_DIRS = -I./MissingKit

ifeq ($(HAVE_CAIRO), YES)
   ADDITIONAL_OBJCFLAGS += -DHAVE_CAIRO
endif

# Use C++ to link library
CC=${CXX}

-include GNUmakefile.preamble


include $(GNUSTEP_MAKEFILES)/aggregate.make
# NOTE: Include etoile.make include before framework.make otherwise the 
# compilation may fail if you type 'make; make' (see bug #8806).
include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble

config.make:
	sh config.sh

after-distclean::
	-$(RM) config.make

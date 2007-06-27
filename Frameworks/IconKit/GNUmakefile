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

PACKAGE_NAME = IconKit

include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = IconKit
ADDITIONAL_LDFLAGS += -lUnitKit -lgnustep-gui -lgnustep-base
ADDITIONAL_CFLAGS += -DHAVE_UKTEST
else
FRAMEWORK_NAME = IconKit
endif

IconKit_SUBPROJECTS = Source

IconKit_RESOURCE_FILES = IconKitInfo.plist GNUstep.icontheme ExtensionMapping.plist

IconKit_HEADER_FILES_DIR = Headers

ifneq ($(test), yes)

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


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble

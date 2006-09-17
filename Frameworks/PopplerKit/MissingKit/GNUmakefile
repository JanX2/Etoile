#
# GNUmakefile
#
# Compile the bindings that are used by the PopplerKit Objective-C
# classes to interface with the poppler library.
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
-include ../config.make

SUBPROJECT_NAME=MissingKit

MissingKit_CFLAGS = \
	-g

MissingKit_OBJC_FILES = \
MKLRUCache.m \
MKLinkedList.m \

ADDITIONAL_OBJCFLAGS = -Wall -Wno-import -DGNUSTEP

include $(GNUSTEP_MAKEFILES)/subproject.make

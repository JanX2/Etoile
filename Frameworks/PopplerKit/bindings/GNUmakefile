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

# Remove LDFLAGS so that it will not try to link in subproject
ADDITIONAL_LDFLAGS =

# use cplusplus compiler
CC = ${CXX}

SUBPROJECT_NAME=bindings

bindings_CFLAGS = -g 

bindings_OBJCFLAGS = -Wno-import

bindings_C_FILES = \
poppler.c \
poppler_document.c \
poppler_page.c \
poppler_splash_renderer.c \
poppler_text.c 

bindings_OBJC_FILES = \
poppler_objc.m

ifeq ($(HAVE_CAIRO), YES)
   bindings_C_FILES += poppler_cairo_img_renderer.c
endif

ifeq ($(POPPLER_0_4), YES)
   bindings_CFLAGS += -DPOPPLER_0_4
endif

ifeq ($(POPPLER_0_5), YES)
   bindings_CFLAGS += -DPOPPLER_0_5
endif

ifeq ($(POPPLER_0_6), YES)
   bindings_CFLAGS += -DPOPPLER_0_6
endif

include $(GNUSTEP_MAKEFILES)/subproject.make

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

# If we decide to move away from truncf as a GCC builtin function, it will be
# mandatory to link C math lib.
# ADDITIONAL_LDFLAGS = -lm 

SUBPROJECT_NAME = libIconKit	

#
# Class files
#
libIconKit_OBJC_FILES= \
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
	
-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble

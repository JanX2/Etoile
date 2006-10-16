#	GNUmakefile
#
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Written by:	Manuel Guesdon <mguesdon@orange-concept.com>
#
#  This file is part of the GNUstep GSCrypt Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

include $(GNUSTEP_MAKEFILES)/common.make


srcdir = .
PACKAGE_NAME = RSSKit

# The library to be compiled
LIBRARY_VAR=RSSKIT
LIBRARY_NAME=libRSSKit

# Install into the system root by default
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

# Additional libraries
libRSSKit_LIBRARIES_DEPEND_UPON += $(FND_LIBS)

# The Objective-C source files to be compiled
libRSSKit_OBJC_FILES = \
RSSArticle.m \
RSSArticle+Storage.m \
RSSFeed.m \
RSSFeed+Fetching.m \
DublinCore.m \
DOMParser.m \
FeedParser.m \
RSS10Parser.m \
RSS20Parser.m \
AtomParser.m \
Atom03Parser.m \
Atom10Parser.m \
RSSArticleCreationListener.m \


libRSSKit_HEADER_FILES = \
RSSArticle.h \
RSSArticle+Storage.h \
RSSFeed.h \
RSSFeed+Fetching.h \
DublinCore.h \
RSSKit.h \
DOMParser.h \
FeedParser.h \
RSS10Parser.h \
RSS20Parser.h \
AtomParser.h \
Atom03Parser.h \
Atom10Parser.h \
RSSArticleCreationListener.h \
NewRSSArticleListener.h \


libRSSKit_HEADER_FILES_DIR = .
libRSSKit_HEADER_FILES_INSTALL_DIR=/RSSKit



#SRCS = $(LIBRARY_NAME:=.m)
#HDRS = RSSFeed.h RSSArticle.h $(LIBRARY_NAME:=.h)
#DIST_FILES = $(SRCS) $(HDRS) GNUmakefile Makefile.postamble Makefile.preamble



include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make

-include GNUmakefile.preamble
-include GNUmakefile.local
-include GNUmakefile.postamble


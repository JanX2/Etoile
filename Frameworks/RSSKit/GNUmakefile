
include $(GNUSTEP_MAKEFILES)/common.make

# Compile with gmake coverage=yes, if you want to have coverage analysis output
ifeq ($(coverage), yes)
ADDITIONAL_FLAGS += -fprofile-arcs -ftest-coverage
ADDITIONAL_OBJC_LIBS += -lgcov
endif


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
RSSFeed+Storage.m \
DublinCore.m \
DOMParser.m \
FeedParser.m \
RSS10Parser.m \
RSS20Parser.m \
AtomParser.m \
Atom03Parser.m \
Atom10Parser.m \
RSSArticleCreationListener.m \
RSSFactory.m \
RSSLinks.m 


libRSSKit_HEADER_FILES = \
RSSArticle.h \
RSSArticle+Storage.h \
RSSArticleProtocol.h \
RSSFeed.h \
RSSFeedProtocol.h \
RSSFeed+Fetching.h \
RSSFeed+Storage.h \
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
RSSFactory.h \
RSSLinks.h 


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


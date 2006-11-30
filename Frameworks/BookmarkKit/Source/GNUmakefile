include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = BookmarkKit
else
LIBRARY_NAME = BookmarkKit
endif
VERSION = 0.1

BookmarkKit_LIBRARIES_DEPEND_UPON = -lCollectionKit
ifeq ($(test), yes)
BookmarkKit_LDFLAGS += -lCollectionKit
endif

BookmarkKit_OBJC_FILES = \
	BKBookmarkView.m \
	BKGroup.m \
	BKBookmarkStore.m \
	BKBookmark.m \
	BKBookmarkQuery.m \
	BKBookmarkSearchResult.m 

ifeq ($(test), yes)
BookmarkKit_OBJC_FILES +=  \
	TestBookmarkStore.m \
	TestGroup.m \
	TestBookmark.m 
endif

BookmarkKit_HEADER_FILES_DIR = ../Headers

BookmarkKit_HEADER_FILES_INSTALL_DIR = BookmarkKit

BookmarkKit_HEADER_FILES = \
	BookmarkKit.h \
	BKGlobals.h \
	BKGroup.h \
	BKBookmark.h \
	BKBookmarkView.h \
	BKBookmarkQuery.h \
	BKBookmarkSearchResult.h \
	BKBookmarkStore.h

-include ../GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include ../GNUmakefile.postamble


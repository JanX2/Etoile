include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = BookmarkKit_Source

BookmarkKit_Source_OBJC_FILES = \
	BKBookmarkStore.m \
	BKBookmark.m \
	BKBookmarkQuery.m \
	BKBookmarkSearchResult.m 

ifeq ($(test), yes)
BookmarkKit_Source_OBJC_FILES +=  \
	TestBookmarkStore.m \
	TestBookmark.m 
endif


BookmarkKit_Source_INCLUDE_DIRS += -I..

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble


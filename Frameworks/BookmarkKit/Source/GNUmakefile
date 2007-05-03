include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libBookmarkKit

libBookmarkKit_LIBRARIES_DEPEND_UPON = -lCollectionKit
ifeq ($(test), yes)
libBookmarkKit_LDFLAGS += -lCollectionKit
endif

libBookmarkKit_OBJC_FILES = \
	BKBookmarkView.m \
	BKGroup.m \
	BKBookmarkStore.m \
	BKBookmark.m \
	BKBookmarkQuery.m \
	BKBookmarkSearchResult.m 

ifeq ($(test), yes)
libBookmarkKit_OBJC_FILES +=  \
	TestBookmarkStore.m \
	TestGroup.m \
	TestBookmark.m 
endif

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble


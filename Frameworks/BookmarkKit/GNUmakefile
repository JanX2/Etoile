include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = BookmarkKit
else
FRAMEWORK_NAME = BookmarkKit
endif
#VERSION = 0.1

BookmarkKit_SUBPROJECTS = Source

BookmarkKit_HEADER_FILES_DIR = Headers

BookmarkKit_HEADER_FILES = \
        BookmarkKit.h \
        BKGlobals.h \
        BKGroup.h \
        BKBookmark.h \
        BKBookmarkView.h \
        BKBookmarkQuery.h \
        BKBookmarkSearchResult.h \
        BKBookmarkStore.h

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble


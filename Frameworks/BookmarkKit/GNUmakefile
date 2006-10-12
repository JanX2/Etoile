include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = BookmarkKit
else
LIBRARY_NAME = BookmarkKit
endif

-include GNUmakefile.headers

BookmarkKit_SUBPROJECTS = Source

ifeq ($(test), yes)
	BookmarkKit_OBJC_LIBS += -framework UnitKit
endif

BookmarkKit_LIBRARIES_DEPEND_UPON = -lCollectionKit
BookmarkKit_LDFLAGS += -lCollectionKit

ADDITIONAL_INCLUDE_DIRS += 
ADDITIONAL_CFLAGS += 
ADDITIONAL_LIB_DIRS += 

-include GNUmakefile.preamble
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include GNUmakefile.headers_build
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble


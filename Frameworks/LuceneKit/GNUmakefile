include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = LuceneKit
else
LIBRARY_NAME = LuceneKit
endif

include GNUmakefile.headers

LuceneKit_SUBPROJECTS = Source

ifeq ($(FOUNDATION_LIB), apple)
        LuceneKit_OBJC_LIBS = -framework UnitKit
else
        #LuceneKit_OBJC_LIBS = -lUnitKit -lgnustep-base
LuceneKit_LDFLAGS = -lUnitKit -lgnustep-base
endif

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

include GNUmakefile.headers_build

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = LuceneKit
ADDITIONAL_LDFLAGS += -DHAVE_UKTEST
else
LIBRARY_NAME = LuceneKit
endif

LuceneKit_SUBPROJECTS = \
	Search \
	Index \
	Analysis \
	Document \
	Store \
	Util \
	Java

ifeq ($(FOUNDATION_LIB), apple)
  LuceneKit_OBJC_LIBS += -framework UnitKit
else
  LuceneKit_OBJC_LIBS += -lUnitKit
endif

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble

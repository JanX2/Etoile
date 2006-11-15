include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = CollectionKit
else
LIBRARY_NAME = CollectionKit
endif

-include GNUmakefile.headers

CollectionKit_SUBPROJECTS = Source

ifeq ($(test), yes)
ifeq ($(FOUNDATION_LIB), apple)
	CollectionKit_OBJC_LIBS += -framework UnitKit
else
	CollectionKit_OBJC_LIBS += -lUnitKit
endif
endif

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
include ../../etoile.make
-include GNUmakefile.postamble


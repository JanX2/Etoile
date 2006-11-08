include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = PaneKit
else
LIBRARY_NAME = PaneKit
endif

-include GNUmakefile.headers

PaneKit_SUBPROJECTS = Source

ifeq ($(test), yes)
	PaneKit_OBJC_LIBS += -framework UnitKit
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


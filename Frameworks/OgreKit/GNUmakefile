include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = OgreKit
else
LIBRARY_NAME = OgreKit
endif

#include GNUmakefile.headers

OgreKit_SUBPROJECTS = Source

ifeq ($(FOUNDATION_LIB), apple)
        OgreKit_OBJC_LIBS = -framework UnitKit -L/opt/local/lib -lonig 
else
	OgreKit_LDFLAGS = -lUnitKit -lgnustep-base -L/opt/local/lib -lonig
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

include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = OgreKit
else
LIBRARY_NAME = OgreKit
endif

include GNUmakefile.headers

OgreKit_SUBPROJECTS = Source

ifeq ($(FOUNDATION_LIB), apple)
	OgreKit_LIBRARIES_DEPEND_UPON = `onig-config --libs` `onig-config --prefix`/lib/libonig.a
	ifeq ($(test), yes)
		OgreKit_OBJC_LIBS += -framework UnitKit `onig-config --libs`
	endif
else
	x := $(shell onig-config --libs)
	BUNDLE_LIBS += $(x)
	OgreKit_LIBRARIES_DEPEND_UPON = $(x)
	OgreKit_LDFLAGS += -lgnustep-base $(x)
	ifeq ($(test), yes)
		OgreKit_OBJC_LIBS += $(x)
		OgreKit_LDFLAGS += -lUnitKit
	endif
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

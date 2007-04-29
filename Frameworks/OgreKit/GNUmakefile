include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = OgreKit
else
FRAMEWORK_NAME = OgreKit
endif

-include GNUmakefile.headers

OgreKit_SUBPROJECTS = Source

OgreKit_LIBRARIES_DEPEND_UPON = `onig-config --libs`

ifeq ($(test), yes)
	OgreKit_OBJC_LIBS += -framework UnitKit
endif

ADDITIONAL_INCLUDE_DIRS += 
ADDITIONAL_CFLAGS += `onig-config --cflags`
ADDITIONAL_LIB_DIRS += `onig-config --libs`

-include GNUmakefile.preamble
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
-include GNUmakefile.postamble


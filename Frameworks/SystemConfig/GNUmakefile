PACKAGE_NAME = SystemConfig

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = SystemConfig

SystemConfig_SUBPROJECTS = Source

SystemConfig_HEADER_FILES_DIR = Headers

SystemConfig_HEADER_FILES = \
        SCConfig.h \
        SCKeyboard.h \
        SCMonitor.h \
        SCMouse.h \
        SCSound.h

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif


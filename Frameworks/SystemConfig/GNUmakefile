PACKAGE_NAME = SystemConfig

# FIXME: Probably better to declare ETOILE_X11 variable in etoile.make
export ETOILE_X11 ?= yes

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

ifeq ($(ETOILE_X11), yes)
SystemConfig_LIBRARIES_DEPEND_UPON += -lX11
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif


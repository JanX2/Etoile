PACKAGE_NAME = SystemConfig

# FIXME: Probably better to declare ETOILE_X11 variable in etoile.make
export ETOILE_X11 ?= yes
export LIBACPI ?= no

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = SystemConfig

SystemConfig_SUBPROJECTS = Source

SystemConfig_HEADER_FILES_DIR = Headers

SystemConfig_HEADER_FILES = \
	SCConfig.h \
	SCKeyboard.h \
	SCMachineInfo.h\
	SCMonitor.h \
	SCMouse.h \
	SCPower.h \
	SCSound.h

ifeq ($(ETOILE_X11), yes)
SystemConfig_LIBRARIES_DEPEND_UPON += -lX11
SystemConfig_HEADER_FILES += X11Keyboard.h
endif

ifeq ($(LIBACPI), yes)
SystemConfig_LIBRARIES_DEPEND_UPON += -lacpi
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif


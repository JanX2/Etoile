include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
SUBPROJECT_NAME = libSystemConfig
VERSION = 0.1

#
# Class files
#
libSystemConfig_OBJC_FILES = \
	SCConfig.m \
	SCKeyboard.m \
	SCMonitor.m \
	SCMouse.m \
	SCPower.m \
	SCPower_Linux.m \
	SCPower_FreeBSD.m \
	SCPower_OpenBSD.m \
	SCSound.m

ifeq ($(ETOILE_X11), yes)
libSystemConfig_OBJC_FILES += X11Mouse.m

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib
endif

ADDITIONAL_INCLUDE_DIRS += -I/usr/include

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble



include $(GNUSTEP_MAKEFILES)/common.make

####################################################
#             WHAT MODULES TO COMPILE              #
####################################################

export X11 ?= yes

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
	SCSound.m

ifeq ($(X11), yes)
libSystemConfig_OBJC_FILES += X11Mouse.m
libSystemConfig_LIBRARIES_DEPEND_UPON += -lX11
ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib
endif

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble



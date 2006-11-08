include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I../Headers

#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
LIBRARY_NAME = libSystemConfig
VERSION = 0.1

#
# Resource files
#
$(LIBRARY_NAME)_RESOURCE_FILES =

$(LIBRARY_NAME)_LOCALIZED_RESOURCE_FILES =

# FIXME: xxx_RESOURCE_DIRS doesn't seem to be take in account at least with
$(LIBRARY_NAME)_RESOURCE_DIRS =

#
# Languages we're localized for
#
$(LIBRARY_NAME)_LANGUAGES = \
	English
	
#
# Class files
#
$(LIBRARY_NAME)_OBJC_FILES = \
	SCConfig.m \
	SCKeyboard.m \
	SCMonitor.m \
	SCMouse.m \
	SCSound.m

#
# Header files (to install)
#
$(LIBRARY_NAME)_HEADER_FILES_DIR = ../Headers

$(LIBRARY_NAME)_HEADER_FILES = \
	SConfig.h \
	SCKeyboard.h \
	SCMonitor.h \
	SCMouse.h \
	SCSound.h

$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = /$(LIBRARY_NAME)

#
# C files
#
$(LIBRARY_NAME)_C_FILES =

-include GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include GNUmakefile.postamble

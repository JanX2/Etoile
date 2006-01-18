include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS += -Wno-import

#
# Main application
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

PACKAGE_NAME = ServicesBarKit	
ifeq ($(test), yes)
BUNDLE_NAME = libServicesBarKit
ADDITIONAL_LDFLAGS = -lUnitKit -lgnustep-gui -lgnustep-base
else
LIBRARY_NAME = libServicesBarKit
endif
VERSION = 0.1

libServicesBarKit_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)

#
# Resource files
#
libServicesBarKit_MAIN_MODEL_FILE =
libServicesBarKit_RESOURCE_FILES =

libServicesBarKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
libServicesBarKit_LANGUAGES = \
	English

#
# Header files
#
libServicesBarKit_HEADERS = \
	SBServicesBarItem.h \
	SBServicesBar.h
	
ifeq ($(test), no)
libServicesBarKit_HEADER_FILES_INSTALL_DIR = /ServicesBarKit
endif


#
# Class files
#
libServicesBarKit_OBJC_FILES = \
	SBServicesBarItem.m \
	SBServicesBar.m

#
# C files
#
libServicesBarKit_C_FILES = 

-include GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include GNUmakefile.postamble

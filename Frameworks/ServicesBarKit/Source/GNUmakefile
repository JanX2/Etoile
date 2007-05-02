include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS += -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../Headers

#
# Main application
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

ifeq ($(test), yes)
BUNDLE_NAME = ServicesBarKit
ADDITIONAL_CPPFLAGS += -DHAVE_UKTEST
ADDITIONAL_LDFLAGS += -lUnitKit -lgnustep-gui -lgnustep-base
else
FRAMEWORK_NAME = ServicesBarKit
endif
VERSION = 0.1

ServicesBarKit_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)

#
# Resource files
#
ServicesBarKit_MAIN_MODEL_FILE =
ServicesBarKit_RESOURCE_FILES =

ServicesBarKit_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
ServicesBarKit_LANGUAGES = \
	English

#
# Header files
#
ServicesBarKit_HEADERS = \
	SBServicesBarItem.h \
	SBServicesBar.h

ServicesBarKit_HEADER_FILES_DIR = ../Headers
	
#
# Class files
#
ServicesBarKit_OBJC_FILES = \
	SBServicesBarItem.m \
	SBServicesBar.m

#
# C files
#
ServicesBarKit_C_FILES =

-include GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble

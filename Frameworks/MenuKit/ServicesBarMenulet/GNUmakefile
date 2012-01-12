include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS += -Wno-import

#
# Main application
#

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)
	
BUNDLE_NAME = ServicesBarMenulet
VERSION = 0.1
BUNDLE_EXTENSION = .menulet

$(BUNDLE_NAME)_LDFLAGS += -lServicesBarKit

#
# Resource files
#
$(BUNDLE_NAME)_MAIN_MODEL_FILE =
$(BUNDLE_NAME)_RESOURCE_FILES = #ServicesBarMenuletInfo.plist

$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
$(BUNDLE_NAME)_LANGUAGES = \
	English

#
# Header files
#
$(BUNDLE_NAME)_HEADERS = 

#
# Class files
#
$(BUNDLE_NAME)_OBJC_FILES = \
	ServicesBarMenulet.m

#
# C files
#
$(BUNDLE_NAME)_C_FILES = 

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

#
#    Makefile for Etoile PreferencesKitExample
#

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

#
# Main application
#
BUNDLE_NAME = SamplePrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane
BUNDLE_INSTALL_DIR = 

SamplePrefPane_PRINCIPAL_CLASS = SamplePrefPane
SamplePrefPane_APPLICATION_ICON =

SamplePrefPane_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
ifeq ($(FOUNDATION_LIB), apple)
SamplePrefPane_MAIN_MODEL_FILE = \
	SamplePrefPane.nib

SamplePrefPane_LOCALIZED_RESOURCE_FILES += \
	SamplePrefPane.nib 

SamplePrefPane_RESOURCE_FILES = \
	SamplePrefPaneIcon.tiff 
else
SamplePrefPane_MAIN_MODEL_FILE = \
	SamplePrefPane.gorm

SamplePrefPane_RESOURCE_FILES = \
	SamplePrefPane.gorm \
	SamplePrefPaneIcon.tiff \
	SamplePrefPaneInfo.plist
endif

SamplePrefPane_LOCALIZED_RESOURCE_FILES +=

#
# Languages we're localized for
#
SamplePrefPane_LANGUAGES = \
	English
	
#
# Class files
#
SamplePrefPane_OBJC_FILES = \
	SamplePrefPane.m

#
# Header files
#
SamplePrefPane_HEADER_FILES = \
	SamplePrefPane.h

#
# C files
#
SamplePrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

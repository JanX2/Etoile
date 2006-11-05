#
#    Makefile for Etoile PreferencesKitExample
#

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

PACKAGE_NAME = SamplePrefsModule.prefsModule

#
# Main application
#
BUNDLE_NAME = SamplePrefsModule
VERSION = 0.1
BUNDLE_EXTENSION = .prefsModule
BUNDLE_INSTALL_DIR = 

SamplePrefsModule_PRINCIPAL_CLASS = SamplePrefsModule
SamplePrefsModule_APPLICATION_ICON =

SamplePrefsModule_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
ifeq ($(FOUNDATION_LIB), apple)
SamplePrefsModule_MAIN_MODEL_FILE = \
	SamplePrefsModule.nib

SamplePrefsModule_LOCALIZED_RESOURCE_FILES = \
	SamplePrefsModule.nib

SamplePrefsModule_RESOURCE_FILES = \
	Preferences.tiff 
else
SamplePrefsModule_MAIN_MODEL_FILE = \
	SamplePrefsModule.gorm

SamplePrefsModule_RESOURCE_FILES = \
	SamplePrefsModule.gorm \
	Preferences.tiff \
	SamplePrefsModuleInfo.plist
endif

SamplePrefsModule_LOCALIZED_RESOURCE_FILES +=

#
# Languages we're localized for
#
SamplePrefsModule_LANGUAGES = \
	English
	
#
# Class files
#
SamplePrefsModule_OBJC_FILES = \
	SamplePrefsModule.m

#
# Header files
#
SamplePrefsModule_HEADER_FILES = \
	SamplePrefsModule.h

#
# C files
#
SamplePrefsModule_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

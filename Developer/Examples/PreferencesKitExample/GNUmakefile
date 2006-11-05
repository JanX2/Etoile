#
#    Makefile for Etoile PreferencesKitExample
#

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = PreferencesKitExample

SUBPROJECTS = SamplePrefPane SamplePrefsModule

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

ADDITIONAL_INSTALL_DIRS = PlugIns

#
# Main application
#
APP_NAME = PreferencesKitExample
VERSION = 0.1

PreferencesKitExample_PRINCIPAL_CLASS = NSApplication
PreferencesKitExample_APPLICATION_ICON =

PreferencesKitExample_GUI_LIBS = -lPreferencesKit

ifeq ($(FOUNDATION_LIB), apple)
PreferencesKitExample_LOCALIZED_RESOURCE_FILES = \
	MainMenu.nib
PreferencesKitExample_MAIN_MODEL_FILE = \
	MainMenu.nib
else
PreferencesKitExample_MAIN_MODEL_FILE = \
	MainMenu.gorm

PreferencesKitExample_RESOURCE_FILES = \
	PreferencesKitExampleInfo.plist \
	MainMenu.gorm

PreferencesKitExample_LOCALIZED_RESOURCE_FILES =
endif

PreferencesKitExample_LANGUAGES = \
	English
	
PreferencesKitExample_OBJC_FILES = \
	main.m

PreferencesKitExample_HEADER_FILES =

PreferencesKitExample_C_FILES =


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I../Headers -I../Headers/BackboneCompatibility

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main application
#
FRAMEWORK_NAME = PreferencesKit
VERSION = 0.1

#
# Resource files
#
PreferencesKit_RESOURCE_FILES = \
	../PrebuiltTableView.gorm

PreferencesKit_LOCALIZED_RESOURCE_FILES =

# FIXME: xxx_RESOURCE_DIRS doesn't seem to be take in account at least with ..
PreferencesKit_RESOURCE_DIRS = ../

#
# Languages we're localized for
#
PreferencesKit_LANGUAGES = \
	English
	
#
# Class files
#
PreferencesKit_OBJC_FILES = \
	CocoaCompatibility.m \
	NSPreferencePane.m \
	PKPreferencesController.m \
	PKPreferencePane.m \
	PKPresentationBuilder.m \
	PKTableViewPreferencesController.m \
	PKMatrixViewPreferencesController.m \
	PKMatrixView.m \
	PKToolbarPreferencesController.m \
	PKPrefPanesRegistry.m \
	UKPluginsRegistry.m \
	PKPrefsModulePrefPane.m

#
# Header files (to install)
#
PreferencesKit_HEADER_FILES = \
	CocoaCompatibility.h \
	NSPreferencePane.h \
	PKPreferencesController.h \
	PKPreferencePane.h \
	PKPresentationBuilder.h \
	PKTableViewPreferencesController.h \
	PKMatrixViewPreferencesController.h \
	PKToolbarPreferencesController.h \
	PKPrefPanesRegistry.h \
	UKPluginsRegistry.h \
	PrefsModule.h \
	PreferencesKit.h

PreferencesKit_HEADER_FILES_DIR = ../Headers

# NOTE: We are not a library anymore, by the way next line is not needed.
#libPreferencesKit_HEADER_FILES_INSTALL_DIR = /PreferencesKit

#
# C files
#
PreferencesKit_C_FILES =

-include GNUmakefile.preamble
-include GNUmakefile.postamble
include $(GNUSTEP_MAKEFILES)/framework.make

# FIXME: GNUmakefile.postamble wasn't called with framework.make until I move
# its declaration above the latter.
#-include GNUmakefile.postamble

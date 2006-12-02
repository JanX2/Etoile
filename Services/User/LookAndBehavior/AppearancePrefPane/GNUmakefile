include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = AppearancePrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

AppearancePrefPane_INSTALL_DIR = 
AppearancePrefPane_STANDARD_INSTALL = no

AppearancePrefPane_PRINCIPAL_CLASS = AppearancePrefPane
AppearancePrefPane_APPLICATION_ICON =

#
# Resource files
#
AppearancePrefPane_MAIN_MODEL_FILE = \
	Appearance.gorm

AppearancePrefPane_RESOURCE_FILES = \
	Appearance.gorm \
	AppearancePrefPaneIcon.tiff \
	AppearancePrefPaneInfo.plist

AppearancePrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
AppearancePrefPane_LANGUAGES = \
	English
	
#
# Class files
#
AppearancePrefPane_OBJC_FILES = \
	AppearancePrefPane.m

#
# C files
#
AppearancePrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

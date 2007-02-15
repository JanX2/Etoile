include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = MousePrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

MousePrefPane_STANDARD_INSTALL = no
MousePrefPane_INSTALL_DIR =

MousePrefPane_PRINCIPAL_CLASS = MousePrefPane
MousePrefPane_APPLICATION_ICON =

MousePrefPane_GUI_LIBS = -lSystemConfig

#
# Resource files
#
MousePrefPane_MAIN_MODEL_FILE = \
	Mouse.gorm

MousePrefPane_RESOURCE_FILES = \
	Mouse.gorm \
	MousePrefPaneInfo.plist

MousePrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
MousePrefPane_LANGUAGES = \
	English
	
#
# Class files
#
MousePrefPane_OBJC_FILES = \
	MousePrefPane.m

#
# C files
#
MousePrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = KeyboardPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

KeyboardPrefPane_STANDARD_INSTALL = no
KeyboardPrefPane_INSTALL_DIR =

KeyboardPrefPane_PRINCIPAL_CLASS = KeyboardPrefPane
KeyboardPrefPane_APPLICATION_ICON =

#
# Resource files
#
KeyboardPrefPane_MAIN_MODEL_FILE = \
	Keyboard.gorm

KeyboardPrefPane_RESOURCE_FILES = \
	Keyboard.gorm \
	KeyboardPrefPaneInfo.plist

KeyboardPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
KeyboardPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
KeyboardPrefPane_OBJC_FILES = \
	KeyboardPrefPane.m

#
# C files
#
KeyboardPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

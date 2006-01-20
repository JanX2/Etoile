include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

#
# Main application
#
BUNDLE_NAME = StartupPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

StartupPrefPane_STANDARD_INSTALL = no
StartupPrefPane_INSTALL_DIR =

StartupPrefPane_PRINCIPAL_CLASS = StartupPrefPane
StartupPrefPane_APPLICATION_ICON =

StartupPrefPane_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
StartupPrefPane_MAIN_MODEL_FILE = \
	Startup.gorm

StartupPrefPane_RESOURCE_FILES = \
	Startup.gorm \
	StartupPrefPaneInfo.plist

StartupPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
StartupPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
StartupPrefPane_OBJC_FILES = \
	StartupPrefPane.m

#
# C files
#
StartupPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

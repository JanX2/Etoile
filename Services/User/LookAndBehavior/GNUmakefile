include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = LookAndBehavior

SUBPROJECTS = AppearancePrefPane LanguagesPrefPane

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

ADDITIONAL_INSTALL_DIRS = PlugIns

#
# Main application
#
APP_NAME = LookAndBehavior
VERSION = 0.1

LookAndBehavior_PRINCIPAL_CLASS = NSApplication
LookAndBehavior_APPLICATION_ICON =

LookAndBehavior_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
LookAndBehavior_MAIN_MODEL_FILE = \
	MainMenu.gorm

LookAndBehavior_RESOURCE_FILES = \
	LookAndBehaviorInfo.plist \
	MainMenu.gorm

LookAndBehavior_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
LookAndBehavior_LANGUAGES = \
	English

#
# Class files
#
LookAndBehavior_OBJC_FILES = \
	main.m

#
# Header files
#
LookAndBehavior_HEADER_FILES =

#
# C files
#
LookAndBehavior_C_FILES =


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble

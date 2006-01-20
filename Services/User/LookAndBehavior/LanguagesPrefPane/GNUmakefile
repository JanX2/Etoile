include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

#
# Main application
#
BUNDLE_NAME = LanguagesPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

LanguagesPrefPane_INSTALL_DIR = 
LanguagesPrefPane_STANDARD_INSTALL = no

LanguagesPrefPane_PRINCIPAL_CLASS = LanguagesPrefPane
LanguagesPrefPane_APPLICATION_ICON =

LanguagesPrefPane_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
LanguagesPrefPane_MAIN_MODEL_FILE = \
	Languages.gorm

LanguagesPrefPane_RESOURCE_FILES = \
	Languages.gorm \
	LanguagesPrefPaneIcon.tiff \
	LanguagesPrefPaneInfo.plist

LanguagesPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
LanguagesPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
LanguagesPrefPane_OBJC_FILES = \
	LanguagesPrefPane.m

#
# C files
#
LanguagesPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

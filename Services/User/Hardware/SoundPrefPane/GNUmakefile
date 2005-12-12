include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

#
# Main application
#
BUNDLE_NAME = SoundPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane
BUNDLE_INSTALL_DIR = 

SoundPrefPane_PRINCIPAL_CLASS = SoundPrefPane
SoundPrefPane_APPLICATION_ICON =

SoundPrefPane_GUI_LIBS = -lPreferencesKit

#
# Resource files
#
SoundPrefPane_MAIN_MODEL_FILE = \
	Sound.gorm

SoundPrefPane_RESOURCE_FILES = \
	Sound.gorm \
	SoundPrefPaneInfo.plist

SoundPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
SoundPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
SoundPrefPane_OBJC_FILES = \
	SoundPrefPane.m

#
# Header files
#
SoundPrefPane_HEADER_FILES = \
	SoundPrefPane.h

#
# C files
#
SoundPrefPane_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

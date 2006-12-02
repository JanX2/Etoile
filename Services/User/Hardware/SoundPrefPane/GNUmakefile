include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = SoundPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

SoundPrefPane_STANDARD_INSTALL = no
SoundPrefPane_INSTALL_DIR =

SoundPrefPane_PRINCIPAL_CLASS = SoundPrefPane
SoundPrefPane_APPLICATION_ICON =

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
# C files
#
SoundPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

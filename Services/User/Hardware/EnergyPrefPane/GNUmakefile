include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = EnergyPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

EnergyPrefPane_STANDARD_INSTALL = no
EnergyPrefPane_INSTALL_DIR =

EnergyPrefPane_PRINCIPAL_CLASS = EnergyPrefPane
EnergyPrefPane_APPLICATION_ICON =

#
# Resource files
#
EnergyPrefPane_MAIN_MODEL_FILE = \
	Energy.gorm

EnergyPrefPane_RESOURCE_FILES = \
	Energy.gorm \
	EnergyPrefPaneInfo.plist

EnergyPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
EnergyPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
EnergyPrefPane_OBJC_FILES = \
	EnergyPrefPane.m

#
# C files
#
EnergyPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

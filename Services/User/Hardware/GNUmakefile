include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = hardware-utility

SUBPROJECTS = \
	EnergyPrefPane \
	KeyboardPrefPane \
	MousePrefPane \
	MonitorPrefPane \
	SoundPrefPane \
	StartupPrefPane

ADDITIONAL_INSTALL_DIRS = PlugIns

#
# Main application
#
APP_NAME = Hardware
VERSION = 0.1

Hardware_PRINCIPAL_CLASS = NSApplication
Hardware_APPLICATION_ICON =
Hardware_GUI_LIBS = -lSystemConfig

#
# Resource files
#
Hardware_MAIN_MODEL_FILE = \
	MainMenu.gorm

Hardware_RESOURCE_FILES = \
	HardwareInfo.plist \
	MainMenu.gorm

Hardware_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
Hardware_LANGUAGES = \
	English
	
#
# Class files
#
Hardware_OBJC_FILES = \
	main.m

#
# Header files
#
Hardware_HEADER_FILES =

#
# C files
#
Hardware_C_FILES =


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../etoile.make

# HACK
extension = app

-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

#
# Main application
#
BUNDLE_NAME = MonitorPrefPane
VERSION = 0.1
BUNDLE_EXTENSION = .prefPane

MonitorPrefPane_STANDARD_INSTALL = no
MonitorPrefPane_INSTALL_DIR =

MonitorPrefPane_PRINCIPAL_CLASS = MonitorPrefPane
MonitorPrefPane_APPLICATION_ICON =

#
# Resource files
#
MonitorPrefPane_MAIN_MODEL_FILE = \
	Monitor.gorm

MonitorPrefPane_RESOURCE_FILES = \
	Monitor.gorm \
	Monitor.png \
	MonitorPrefPaneInfo.plist

MonitorPrefPane_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
MonitorPrefPane_LANGUAGES = \
	English
	
#
# Class files
#
MonitorPrefPane_OBJC_FILES = \
	MonitorPrefPane.m

#
# C files
#
MonitorPrefPane_C_FILES =

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble

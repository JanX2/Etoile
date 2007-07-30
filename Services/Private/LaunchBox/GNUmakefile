include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
APP_NAME = LaunchBox

#
# Resource files
#
LaunchBox_LANGUAGES = English

LaunchBox_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.nib

LaunchBox_OBJC_FILES = \
	LaunchBox.m\
	main.m

LaunchBox_PRINCIPLE_CLASS = LaunchBox

ADDITIONAL_OBJCFLAGS += -werror -g
ADDITIONAL_OBJCFLAGS = -std=c99 -Wno-import 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

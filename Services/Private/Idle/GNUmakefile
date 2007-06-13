ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = Idle

#
# Resource files
#
Idle_LANGUAGES = English

#Idle_RESOURCE_FILES = Idle.plist

#Idle_LOCALIZED_RESOURCE_FILES = \
	  #MainMenu.gorm

#Idle_MAIN_MODEL_FILE = MainMenu.gorm

Idle_OBJC_FILES = \
	XIdle.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror
ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11 -lXss

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make

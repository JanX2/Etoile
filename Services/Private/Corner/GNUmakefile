ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
APP_NAME = Corner

#
# Resource files
#
Corner_LANGUAGES = English

Corner_RESOURCE_FILES = Corner.plist

Corner_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.gorm

Corner_MAIN_MODEL_FILE = MainMenu.gorm

Corner_OBJC_FILES = \
	Corner.m\
	main.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror
ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11
ADDITIONAL_LDFLAGS += -lStepTalk -g

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

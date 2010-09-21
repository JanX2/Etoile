include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
APP_NAME = StatusExample

#
# Resource files
#
StatusExample_LANGUAGES = English

StatusExample_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.gorm

StatusExample_MAIN_MODEL_FILE = MainMenu.gorm

StatusExample_OBJC_FILES = \
	StatusExample.m\
	main.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror
ADDITIONAL_LDFLAGS += -g


include $(GNUSTEP_MAKEFILES)/application.make

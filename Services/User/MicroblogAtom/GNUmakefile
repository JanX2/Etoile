include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = StatusAtom

#
# Resource files
#
StatusAtom_LANGUAGES = English

StatusAtom_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.gorm

StatusAtom_MAIN_MODEL_FILE = MainMenu.gorm

StatusAtom_OBJC_FILES = \
	StatusAtom.m\
	main.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror
ADDITIONAL_LDFLAGS += -g


include $(GNUSTEP_MAKEFILES)/tool.make

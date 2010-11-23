include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
TOOL_NAME = StatusAtom

StatusAtom_LANGUAGES = English

StatusAtom_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.gorm

StatusAtom_MAIN_MODEL_FILE = MainMenu.gorm

StatusAtom_OBJC_FILES = \
	StatusAtom.m\
	main.m

StatusAtom_OBJCFLAGS = -std=c99
StatusAtom_TOOL_LIBS = -lEtoileFoundation -lgnustep-gui

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make

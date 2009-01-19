include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = CodeMonkey

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_MAIN_MODEL_FILE = Browser.gorm
$(APP_NAME)_RESOURCE_FILES = Browser.gorm PrettyPrintCategories.st PrettyPrintWriter.st
$(APP_NAME)_GUI_LIBS = -lSmalltalkSupport -lLanguageKit # -lMediaKit -lEtoileUI -lCoreObject -lIconKit
OBJCFLAGS += -std=c99

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

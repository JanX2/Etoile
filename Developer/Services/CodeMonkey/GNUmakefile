include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = CodeMonkey

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_MAIN_MODEL_FILE = Browser.gorm
$(APP_NAME)_RESOURCE_FILES = default.gorm Browser.gorm LKInfo.plist PrettyPrintCategories.st PrettyPrintWriter.st
$(APP_NAME)_GUI_LIBS = -lSmalltalkSupport -lLanguageKit -lCoreObject
 # -lMediaKit -lEtoileUI -lCoreObject -lIconKit
$(APP_NAME)_INCLUDE_DIRS = -I`pg_config --includedir`
$(APP_NAME)_LIB_DIRS = -I`pg_config --libdir`
OBJCFLAGS += -std=c99 -DCOREOBJECT

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

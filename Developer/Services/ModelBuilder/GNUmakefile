include $(GNUSTEP_MAKEFILES)/common.make

CC=clang

APP_NAME = ModelBuilder

$(APP_NAME)_OBJCFLAGS += -Wparentheses -fblocks
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lEtoileUI -lIconKit -lEtoileSerialize

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)

$(APP_NAME)_LANGUAGES = English
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_MAIN_MODEL_FILE = MainMenu.gorm
$(APP_NAME)_LOCALIZED_RESOURCE_FILES = MainMenu.gorm

include $(GNUSTEP_MAKEFILES)/application.make


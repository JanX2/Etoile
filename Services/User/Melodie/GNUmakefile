include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I.  -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format
# Taglib
# In Ubuntu, libtag_c doesn't have pkg-config data
ADDITIONAL_LDFLAGS += `pkg-config --libs taglib` -ltag_c
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags taglib`
# mp4v2
ADDITIONAL_LDFLAGS += -lmp4v2
APP_NAME = Melodie
$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm
$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm $(APP_NAME).tiff Melodie.st
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lCoreObject -lIconKit -lMediaKit -lEtoileUI -lSmalltalkKit -lSmalltalkSupport

include $(GNUSTEP_MAKEFILES)/application.make

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I.  -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format

# Taglib
# In Ubuntu, libtag_c doesn't have pkg-config data
ADDITIONAL_LDFLAGS += `pkg-config --libs taglib` -ltag_c
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags taglib`
# mp4v2
ADDITIONAL_LDFLAGS += -lmp4v2
# CoreObject
ADDITIONAL_INCLUDE_DIRS += -I`pg_config --includedir`
ADDITIONAL_LIB_DIRS += -L`pg_config --libdir`

APP_NAME = Melodie

$(APP_NAME)_APPLICATION_ICON = $(APP_NAME).tiff
$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm
$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm $(APP_NAME).tiff $(wildcard *.st)
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lCoreObject -lIconKit -lMediaKit -lEtoileUI
$(APP_NAME)_GUI_LIBS += -lSmalltalkKit -lSmalltalkSupport -lLanguageKit

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

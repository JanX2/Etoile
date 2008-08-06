include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags gstreamer-0.10` `pkg-config --cflags taglib_c`
ADDITIONAL_LIB_DIRS += `pkg-config --libs gstreamer-0.10` `pkg-config --libs taglib_c`

APP_NAME = lastfm
$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm
$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm $(APP_NAME).tiff
$(APP_NAME)_GUI_LIBS = -lEtoileUI -lCoreObject -lIconKit

include $(GNUSTEP_MAKEFILES)/application.make

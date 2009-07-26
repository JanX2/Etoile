include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

APP_NAME = Sketch

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)

$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_RESOURCE_FILES = $(APP_NAME)Info.plist

$(APP_NAME)_GUI_LIBS = -lEtoileUI -lEtoilePaint

include $(GNUSTEP_MAKEFILES)/application.make

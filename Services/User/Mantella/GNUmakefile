include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Mantella

Mantella_OBJC_FILES = \
	main.m \
	Controller.m \
	BrowserWindow.m

ADDITIONAL_OBJCFLAGS += `pkg-config --cflags firefox-gtkmozembed`
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags gtk+-2.0`

ADDITIONAL_LIB_DIRS += `pkg-config --libs firefox-gtkmozembed`
ADDITIONAL_LIB_DIRS += `pkg-config --libs gtk+-2.0`
ADDITIONAL_LIB_DIRS += -lXWindowServerKit

include $(GNUSTEP_MAKEFILES)/application.make


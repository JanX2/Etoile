include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Babbler

Babbler_OBJC_FILES = \
	main.m \
	Controller.m \
	Player.m

ADDITIONAL_OBJCFLAGS += `pkg-config --cflags gstreamer-plugins-base-0.10`
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags libgnomeui-2.0`
ADDITIONAL_LDFLAGS += `pkg-config --libs gstreamer-plugins-base-0.10`
ADDITIONAL_LDFLAGS += `pkg-config --libs libgnomeui-2.0`
ADDITIONAL_LDFLAGS += -lgstaudio-0.10

ADDITIONAL_LIB_DIRS += -lXWindowServerKit

include $(GNUSTEP_MAKEFILES)/application.make


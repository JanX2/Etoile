include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = busy_window

busy_window_OBJC_FILES = \
	main.m

# Xwindow
ADDITIONAL_INCLUDE_DIRS += \
	-I/usr/X11R6/include 

ADDITIONAL_LDFLAGS += \
	-L/usr/X11R6/lib \
	-lX11 \
	-lXext

include $(GNUSTEP_MAKEFILES)/tool.make


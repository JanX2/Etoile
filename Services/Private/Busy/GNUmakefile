ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Busy

Busy_OBJC_FILES = \
	AZClient.m \
	Busy.m \
	main.m

# Xwindow
ADDITIONAL_INCLUDE_DIRS += \
	-I/usr/X11R6/include 

ADDITIONAL_LIB_DIRS+= \
	-L/usr/X11R6/lib

ADDITIONAL_GUI_LIBS += \
	-lX11 \
	-lXWindowServerKit \
	-lXext

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make


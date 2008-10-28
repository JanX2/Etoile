ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = AZSwitch

AZSwitch_OBJC_FILES = \
	AZClientCell.m \
	AZSwitchingWindow.m \
	AZClient.m \
	AZSwitch.m \
	main.m

AZSwitch_GUI_LIBS += -lX11 -lXWindowServerKit

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include 
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make


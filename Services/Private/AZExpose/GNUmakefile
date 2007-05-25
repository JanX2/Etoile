include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = AZExpose

AZExpose_OBJC_FILES = \
	AZClientCell.m \
	AZSwitchingWindow.m \
	AZClient.m \
	AZExpose.m \
	main.m

# Xwindow
ADDITIONAL_INCLUDE_DIRS += \
	-I/usr/X11R6/include 

ADDITIONAL_LIB_DIRS += \
	-L/usr/X11R6/lib -lX11 \
	-lXWindowServerKit \
	-lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make


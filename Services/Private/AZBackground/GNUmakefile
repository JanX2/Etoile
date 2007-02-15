ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = AZBackground

AZBackground_OBJC_FILES = \
	AZBackground.m \
	main.m 

ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include 

ADDITIONAL_LIB_DIRS += -L/usr/lib -L/usr/X11R6/lib -lX11 -lXWindowServerKit

ADDITIONAL_GUI_LIBS += 

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make




include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

DEPENDENCIES = XWindowServerKit

APP_NAME = AZDock

AZDock_OBJC_FILES = \
	AZDockView.m \
	AZDockApp.m \
	AZDock.m \
	main.m 

ADDITIONAL_INCLUDE_DIRS += -I/usr/include 

ADDITIONAL_LIB_DIRS += -L/usr/lib -lX11 -lXWindowServerKit

ADDITIONAL_GUI_LIBS += 

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../../etoile.make


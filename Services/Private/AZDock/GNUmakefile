
include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

DEPENDENCIES = XWindowServerKit

APP_NAME = AZDock

AZDock_OBJC_FILES = \
	AZWorkspaceView.m \
	AZDockView.m \
	AZDockApp.m \
	AZDock.m \
	main.m 

AZDock_RESOURCE_FILES = Unknown.tiff

ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include

ADDITIONAL_LIB_DIRS += -L/usr/lib -L/usr/X11R6/lib -lX11 -lXWindowServerKit

ADDITIONAL_GUI_LIBS += 

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../../etoile.make


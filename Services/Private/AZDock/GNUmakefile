include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = \
	XWindowServerKit \
	BookmarkKit

APP_NAME = AZDock

AZDock_OBJC_FILES = \
	AZXWindowApp.m \
	AZGNUstepApp.m \
	AZDockApp.m \
	AZWorkspaceView.m \
	AZDockView.m \
	AZDock.m \
	main.m 

AZDock_RESOURCE_FILES = Unknown.tiff

ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include

ADDITIONAL_LIB_DIRS += \
	-L/usr/lib -L/usr/X11R6/lib -lX11 \
	-lXWindowServerKit \
	-lBookmarkKit \
	-lCollectionKit

ADDITIONAL_GUI_LIBS += 

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../../etoile.make


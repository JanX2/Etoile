ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = XWindowServerKit

XWindowServerKit_OBJC_FILES = \
	XFunctions.m \
	XScreen.m \
	XWindow.m 

XWindowServerKit_LIBRARIES_DEPEND_UPON = -lX11 
XWindowServerKit_HEADER_FILES = \
	XFunctions.h \
	XScreen.h \
	XWindow.h \
	gnustep.h

XWindowServerKit_RESOURCE_FILES = ScriptingInfo.plist

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make


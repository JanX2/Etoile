include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = XWindowServerKit

XWindowServerKit_OBJC_FILES = \
	XWindow.m \
	prop.m

XWindowServerKit_LIBRARIES_DEPEND_UPON = -lX11 
XWindowServerKit_HEADER_FILES_INSTALL_DIR = XWindowServerKit
XWindowServerKit_HEADER_FILES = \
	XWindow.h \
	prop.h \
	gnustep.h

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11

include $(GNUSTEP_MAKEFILES)/library.make


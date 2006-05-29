include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = XWindowServerKit

XWindowServerKit_OBJC_FILES = \
	XScreen.m \
	XWindow.m 

XWindowServerKit_LIBRARIES_DEPEND_UPON = -lX11 
XWindowServerKit_HEADER_FILES_INSTALL_DIR = XWindowServerKit
XWindowServerKit_HEADER_FILES = \
	XScreen.h \
	XWindow.h \
	gnustep.h

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11

include $(GNUSTEP_MAKEFILES)/library.make


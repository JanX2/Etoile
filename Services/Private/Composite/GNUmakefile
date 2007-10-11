ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = Composite

#
# Resource files
#
Composite_LANGUAGES = English

Composite_OBJC_FILES = \
	CompositeDisplay.m \
	CompositeWindow.m \
	Shadow.m\
	xcompmgr.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Wno-unused # -Werror
ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lX11 -lm -lXdamage -lXcomposite -lXrender #-lXWindowServerKit -lgnustep-gui

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make

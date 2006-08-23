include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = XWindowServerKit

BUNDLE_NAME = WorkspaceSwitcher

WorkspaceSwitcher_OBJC_FILES = WorkspaceSwitcher.m 

ADDITIONAL_CPPFLAGS += -DXWindowServerKit -I/usr/X11R6/include


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
-include GNUmakefile.postamble


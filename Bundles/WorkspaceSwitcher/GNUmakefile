include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = WorkspaceSwitcher

WorkspaceSwitcher_OBJC_FILES = WorkspaceSwitcher.m 

ADDITIONAL_LDFLAGS = -lXWindowServerKit
ADDITIONAL_CPPFLAGS += -DXWindowServerKit -I/usr/X11R6/include


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble


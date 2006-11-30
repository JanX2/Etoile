include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/lib -L/usr/X11R6/lib -lX11

SUBPROJECTS = Source

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make

-include GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = MultimediaKit

-include GNUmakefile.headers

MultimediaKit_SUBPROJECTS = Source

ADDITIONAL_CFLAGS += 
ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += \
        -L/usr/lib -L/usr/X11R6/lib -lX11 


-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.headers_build
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
-include GNUmakefile.postamble


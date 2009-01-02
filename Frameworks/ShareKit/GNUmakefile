include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = ShareKit

ShareKit_SUBPROJECTS = \
	shttpd 

ShareKit_OBJC_FILES = \
	SHServer.m \
	SHClient.m 

ShareKit_HEADER_FILES = \
	SHServer.h \
	SHClient.h

#SUBPROJECTS = \
#	ShareApp

ADDITIONAL_OBJCFLAGS += `curl-config --cflags`
ADDITIONAL_LDFLAGS += `curl-config --libs` -lssl

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble

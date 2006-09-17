include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME=adserver

adserver_OBJC_FILES=adserver.m
adserver_OBJCFLAGS=-I../Frameworks -Wall
adserver_LDFLAGS=\
	-L../Frameworks/Addresses/Addresses.framework/Versions/A     \
	-lAddresses
-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

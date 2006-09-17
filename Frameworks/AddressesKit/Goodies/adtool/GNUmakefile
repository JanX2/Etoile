include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME=adtool

adtool_OBJC_FILES=addresstool.m
adtool_OBJCFLAGS=-I../Frameworks -Wall
adtool_LDFLAGS=\
	-L../Frameworks/Addresses/Addresses.framework/Versions/A     \
	-lAddresses
-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

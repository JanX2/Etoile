include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
TOOL_NAME = SrcToRTF 

SrcToRTF_OBJC_FILES = \
				  SrcToRTF.m

CC=clang
ADDITIONAL_OBJCFLAGS += -fobjc-nonfragile-abi 

ADDITIONAL_LDFLAGS += -lgnustep-gui -lSourceCodeKit

include $(GNUSTEP_MAKEFILES)/tool.make

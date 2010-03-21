include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = EtoileText
TOOL_NAME = EtoileTextExample

EtoileText_OBJC_FILES = \
					   ETTextFragment.m\
					   ETTextDocument.m\
					   ETTextTree.m\
					   ETTextStorage.m\
					   ETXMLTextParser.m

EtoileText_HEADER_FILES = \

ADDITIONAL_OBJCFLAGS = -g -Werror -fobjc-nonfragile-abi
CC=clang

ADDITIONAL_LDFLAGS += -lgnustep-gui -lCoreObject

EtoileTextExample_OBJC_FILES = $(EtoileText_OBJC_FILES)\
							   ETTextExample.m

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/tool.make
#-include ../../documentation.make

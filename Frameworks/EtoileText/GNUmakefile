include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = EtoileText
TOOL_NAME = EtoileTextExample TeXtoHTML

EtoileText_OBJC_FILES = \
					   ETTeXScanner.m\
					   ETTextDocument.m\
					   ETTextFragment.m\
					   ETTextStorage.m\
					   ETTextStyles.m\
					   ETTextTree.m\
					   ETTextTreeBuilder.m\
					   ETXMLTextParser.m

EtoileText_HEADER_FILES = \

ADDITIONAL_OBJCFLAGS = -g -Werror -fobjc-nonfragile-abi
CC=clang

ADDITIONAL_LDFLAGS += -lgnustep-gui -lCoreObject

EtoileTextExample_OBJC_FILES = $(EtoileText_OBJC_FILES)\
							   ETTextExample.m

TeXtoHTML_OBJC_FILES = $(EtoileText_OBJC_FILES)\
							   TRTeXToHTML.m

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/tool.make
#-include ../../documentation.make

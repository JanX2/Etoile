include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = EtoileText
#TOOL_NAME = EtoileTextExample TeXtoHTML

EtoileText_OBJC_FILES = \
					   ETTeXHandlers.m\
					   ETTeXScanner.m\
					   ETTextDocument.m\
					   ETTextFragment.m\
					   ETTextStorage.m\
					   ETTextTree.m\
					   ETTextTreeBuilder.m\
					   ETTextTypes.m\
					   ETXMLTextParser.m

EtoileText_HEADER_FILES = \
	ETStyleBuilder.h\
	ETTeXHandlers.h\
	ETTeXScanner.h\
	ETTextDocument.h\
	ETTextFragment.h\
	ETTextProtocols.h\
	ETTextStorage.h\
	ETTextTree.h\
	ETTextTreeBuilder.h\
	ETTextTypes.h\
	ETXMLTextParser.h\
	EtoileText.h

ADDITIONAL_OBJCFLAGS += -fobjc-nonfragile-abi
#ADDITIONAL_OBJCFLAGS += -Werror 
CC=clang

ADDITIONAL_LDFLAGS += -lgnustep-gui -lCoreObject -lEtoileUI

EtoileTextExample_OBJC_FILES = $(EtoileText_OBJC_FILES)\
							   ETTextExample.m

TeXtoHTML_OBJC_FILES = $(EtoileText_OBJC_FILES)\
							   TRTeXToHTML.m

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/tool.make
#-include ../../documentation.make


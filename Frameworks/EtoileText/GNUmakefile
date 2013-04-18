include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = EtoileText

ifeq ($(build_examples), yes)
  TOOL_NAME = EtoileTextExample TeXtoHTML
endif

ifeq ($(test), yes)
  BUNDLE_NAME = $(FRAMEWORK_NAME)
endif

EtoileText_OBJC_FILES = \
	ETTeXHandlers.m\
	ETTeXScanner.m\
	ETTextDocument.m\
	ETTextFragment.m\
	ETTextHTML.m\
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
	ETTextHTML.h\
	ETTextProtocols.h\
	ETTextStorage.h\
	ETTextTree.h\
	ETTextTreeBuilder.h\
	ETTextTypes.h\
	ETXMLTextParser.h\
	EtoileText.h

ifeq ($(test), yes)
  EtoileText_OBJC_FILES += \
	Tests/TestCommon.m\
	Tests/TestTextStorage.m\
	Tests/TestTextTree.m
endif

EtoileTextExample_OBJC_FILES = $(EtoileText_OBJC_FILES)\
	ETTextExample.m

TeXtoHTML_OBJC_FILES = $(EtoileText_OBJC_FILES)\
	TRTeXToHTML.m

ADDITIONAL_OBJCFLAGS += -fobjc-nonfragile-abi
#ADDITIONAL_OBJCFLAGS += -Werror
ADDITIONAL_LDFLAGS = -lCoreObject -lEtoileFoundation -lEtoileXML $(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)
TeXtoHTML_LDFLAGS += -lSourceCodeKit
CC=clang

ifeq ($(test), yes)
  include $(GNUSTEP_MAKEFILES)/bundle.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
  include $(GNUSTEP_MAKEFILES)/tool.make
endif
-include ../../etoile.make
-include etoile.make
#-include ../../documentation.make


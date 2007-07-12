include $(GNUSTEP_MAKEFILES)/common.make

OBJCFLAGS += -g -std=c99
LIBRARY_NAME = TRXML
DOCUMENT_NAME = ${LIBRARY_NAME}

TRXML_OBJC_FILES = TRXMLNode.m\
                   TRXMLNullHandler.m\
                   TRXMLParser.m\
                   TRXMLString.m

TRXML_HEADER_FILES = TRXMLNode.h\
                     TRXMLParser.h\
                     TRXMLString.h\
                     TRXMLNullHandler.h\
                     TRXMLParserDelegate.h

TRXML_AGSDOC_FILES = ${TRXML_HEADER_FILES}

include $(GNUSTEP_MAKEFILES)/library.make
ifneq ($(FOUNDATION_LIB), apple)
# Do not build document for Cocoa.
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

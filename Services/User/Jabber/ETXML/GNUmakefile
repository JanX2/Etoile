include $(GNUSTEP_MAKEFILES)/common.make

OBJCFLAGS += -g -std=c99
LIBRARY_NAME = ETXML
DOCUMENT_NAME = ${LIBRARY_NAME}

ETXML_OBJC_FILES = \
	ETXMLNode.m \
	ETXMLDeclaration.m \
	ETXMLNullHandler.m \
	ETXMLParser.m \
	ETXMLXHTML-IMParser.m\
	ETXMLString.m

ETXML_HEADER_FILES = \
	ETXMLNode.h \
	ETXMLDeclaration.h \
	ETXMLParser.h \
	ETXMLString.h \
	ETXMLNullHandler.h \
	ETXMLXHTML-IMParser.h\
	ETXMLParserDelegate.h

ETXML_AGSDOC_FILES = ${ETXML_HEADER_FILES}

include $(GNUSTEP_MAKEFILES)/library.make
ifneq ($(FOUNDATION_LIB), apple)
# Do not build document for Cocoa.
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

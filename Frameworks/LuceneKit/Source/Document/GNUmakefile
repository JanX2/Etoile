include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Document

ifeq ($(test), yes)
ADDITIONAL_OBJCFLAGS += -DHAVE_UKTEST
endif

LuceneKit_Document_OBJC_FILES = \
	LCNumberTools.m \
	LCDateTools.m \
	LCField.m \
	LCDocument.m

LuceneKit_Document_INCLUDE_DIRS += -I../ -I../../Headers

include $(GNUSTEP_MAKEFILES)/subproject.make

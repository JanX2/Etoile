include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Java

ifeq ($(test), yes)
ADDITIONAL_OBJCFLAGS += -DHAVE_UKTEST
endif

LuceneKit_Java_OBJC_FILES = \
	LCStringReader.m

LuceneKit_Java_INCLUDE_DIRS += -I../ -I../../Headers

include $(GNUSTEP_MAKEFILES)/subproject.make

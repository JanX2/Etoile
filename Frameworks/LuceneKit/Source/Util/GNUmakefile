include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Util

ifeq ($(test), yes)
ADDITIONAL_OBJCFLAGS += -DHAVE_UKTEST
endif

LuceneKit_Util_OBJC_FILES = \
	NSString_Additions.m \
	LCBitVector.m \
	LCPriorityQueue.m 

LuceneKit_Util_INCLUDE_DIRS += -I../../Headers -I../

include $(GNUSTEP_MAKEFILES)/subproject.make

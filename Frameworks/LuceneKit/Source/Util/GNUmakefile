include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Util

LuceneKit_Util_OBJC_FILES = \
	NSString+Additions.m \
	NSData+Additions.m \
	LCBitVector.m \
	LCPriorityQueue.m 

ifeq ($(test), yes)
LuceneKit_Util_OBJC_FILES += \
	TestBitVector.m 
endif


LuceneKit_Util_INCLUDE_DIRS += -I../..

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include ../../GNUmakefile.postamble

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Store

LuceneKit_Store_OBJC_FILES = \
	LCIndexInput.m \
	LCIndexOutput.m \
	LCRAMFile.m \
	LCRAMInputStream.m \
	LCRAMOutputStream.m \
	LCRAMDirectory.m \
	LCFSIndexInput.m \
	LCFSIndexOutput.m \
	LCFSDirectory.m

ifeq ($(test), yes)
LuceneKit_Store_OBJC_FILES += TestStore.m
ADDITIONAL_OBJCFLAGS += -DHAVE_UKTEST
endif


LuceneKit_Store_INCLUDE_DIRS += -I../../Headers -I../

include $(GNUSTEP_MAKEFILES)/subproject.make

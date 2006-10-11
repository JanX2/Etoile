include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = CollectionKit_Source

CollectionKit_Source_OBJC_FILES = \
	CKCollection.m \
	CKGroup.m \
	CKItem.m \
	CKMultiValue.m \
	CKRecord.m \
	CKGlobals.m

ifeq ($(test), yes)
CollectionKit_Source_OBJC_FILES +=  \
	TestCollection.m \
	TestRecord.m \
	TestMultiValue.m 
endif


CollectionKit_Source_INCLUDE_DIRS += -I..

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble


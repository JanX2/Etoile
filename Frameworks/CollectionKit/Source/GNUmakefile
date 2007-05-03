include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libCollectionKit

libCollectionKit_OBJC_FILES = \
	CKCollectionView.m \
	CKSearchElement.m \
	CKCollection.m \
	CKGroup.m \
	CKItem.m \
	CKMultiValue.m \
	CKRecord.m \
	CKGlobals.m

ifeq ($(test), yes)
libCollectionKit_OBJC_FILES +=  \
	TestSearchElement.m \
	TestCollection.m \
	TestRecord.m \
	TestMultiValue.m 
endif

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble

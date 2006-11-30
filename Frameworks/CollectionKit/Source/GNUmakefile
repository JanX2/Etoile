include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = CollectionKit
else
LIBRARY_NAME = CollectionKit
endif
VERSION = 0.1

CollectionKit_OBJC_FILES = \
	CKCollectionView.m \
	CKSearchElement.m \
	CKCollection.m \
	CKGroup.m \
	CKItem.m \
	CKMultiValue.m \
	CKRecord.m \
	CKGlobals.m

ifeq ($(test), yes)
CollectionKit_OBJC_FILES +=  \
	TestSearchElement.m \
	TestCollection.m \
	TestRecord.m \
	TestMultiValue.m 
endif

CollectionKit_HEADER_FILES_DIR = ../Headers

CollectionKit_HEADER_FILES_INSTALL_DIR = CollectionKit

CollectionKit_HEADER_FILES = \
	CollectionKit.h \
	CKCollectionView.h \
	CKSearchElement.h \
	CKCollection.h \
	CKGroup.h \
	CKItem.h \
	CKTypedefs.h \
	CKMultiValue.h \
	CKRecord.h \
	CKGlobals.h

-include ../GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include ../GNUmakefile.postamble

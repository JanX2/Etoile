include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = CollectionKit
else
FRAMEWORK_NAME = CollectionKit
endif
#VERSION = 0.1

CollectionKit_SUBPROJECTS = Source

CollectionKit_HEADER_FILES_DIR = Headers

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


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble

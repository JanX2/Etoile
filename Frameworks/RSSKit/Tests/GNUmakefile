
include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

BUNDLE_NAME = RSSKitTests
RSSKitTests_OBJC_FILES= RSSKitTests.m RDFTests.m
RSSKitTests_HEADER_FILES = RSSKitTests.h RSSKitTests.h

RSSKitTests_OBJC_LIBS= -lUnitKit -lRSSKit

RSSKitTests_RESOURCE_FILES = \
Resources/tests/wellformed/rdf/rdf_channel_description.xml \


include $(GNUSTEP_MAKEFILES)/bundle.make

 

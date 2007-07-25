include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = ViennaTest

ViennaTest_OBJC_FILES = \
	OPML.m \
	Criteria.m \
	RSS.m \
	HTML.m

ifeq ($(FOUNDATION_LIB), apple)
ADDITIONAL_LDFLAGS = -framework UnitKit -lTRXML
else
ADDITIONAL_LDFLAGS = -lUnitKit -lTRXML
endif

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


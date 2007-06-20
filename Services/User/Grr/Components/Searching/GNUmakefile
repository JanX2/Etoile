

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Searching
BUNDLE_EXTENSION = .grrc

$(BUNDLE_NAME)_STANDARD_INSTALL=no

Searching_OBJC_FILES = \
	Searching.m \
	NSSet+ArticleFiltering.m \


Searching_HEADERS = \
	Searching.h \
	NSSet+ArticleFiltering.h \


Searching_PRINCIPAL_CLASS = SearchingComponent

Searching_LANGUAGES = English German

Searching_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


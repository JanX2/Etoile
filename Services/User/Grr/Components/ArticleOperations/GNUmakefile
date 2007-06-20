

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = ArticleOperations
BUNDLE_EXTENSION = .grrc

$(BUNDLE_NAME)_STANDARD_INSTALL=no

ArticleOperations_OBJC_FILES = \
	ArticleOperations.m

ArticleOperations_HEADERS = \
	ArticleOperations.h

ArticleOperations_PRINCIPAL_CLASS = ArticleOperationsComponent

ArticleOperations_LANGUAGES = English German

ArticleOperations_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


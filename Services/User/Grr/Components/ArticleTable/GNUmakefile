

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = ArticleTable
BUNDLE_EXTENSION = .grrc

$(BUNDLE_NAME)_STANDARD_INSTALL=no

ArticleTable_OBJC_FILES = \
	ArticleTablePlugin.m

ArticleTable_HEADERS = \
	ArticleTablePlugin.h

ArticleTable_PRINCIPAL_CLASS = ArticleTablePlugin

ArticleTable_LANGUAGES = English German

ArticleTable_LOCALIZED_RESOURCE_FILES = \
	ArticleTablePlugin.gorm \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble




include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = ArticleDatabase
BUNDLE_EXTENSION = .grrdb

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

ArticleDatabase_OBJC_FILES = \
	ArticleDatabaseComponent.m \

ArticleDatabase_HEADERS = \
	ArticleDatabaseComponent.h \

ArticleDatabase_PRINCIPAL_CLASS = ArticleDatabaseComponent


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble




include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = FeedTable
BUNDLE_EXTENSION = .grrc

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

FeedTable_OBJC_FILES = \
	FeedTablePlugin.m

FeedTable_HEADERS = \
	FeedTablePlugin.h

FeedTable_PRINCIPAL_CLASS = FeedTablePlugin

FeedTable_LANGUAGES = English German

FeedTable_LOCALIZED_RESOURCE_FILES = \
	FeedTablePlugin.gorm \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


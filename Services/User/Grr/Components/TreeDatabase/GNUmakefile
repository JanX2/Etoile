

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = TreeDatabase
BUNDLE_EXTENSION = .grrdb

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

TreeDatabase_OBJC_FILES = \
	TreeDatabaseComponent.m \

TreeDatabase_HEADERS = \
	TreeDatabaseComponent.h \

TreeDatabase_PRINCIPAL_CLASS = TreeDatabaseComponent


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


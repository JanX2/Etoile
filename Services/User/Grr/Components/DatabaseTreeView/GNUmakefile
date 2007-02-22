

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = DatabaseTreeView
BUNDLE_EXTENSION = .grrc

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

DatabaseTreeView_OBJC_FILES = \
	DatabaseTreeViewController.m

DatabaseTreeView_HEADERS = \
	DatabaseTreeViewController.h

DatabaseTreeView_PRINCIPAL_CLASS = DatabaseTreeViewController

DatabaseTreeView_LANGUAGES = English German

DatabaseTreeView_LOCALIZED_RESOURCE_FILES = \
	DatabaseTreeViewController.gorm \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


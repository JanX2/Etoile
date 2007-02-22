

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = DatabaseOperations
BUNDLE_EXTENSION = .grrc

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

DatabaseOperations_OBJC_FILES = \
	DatabaseOperations.m

DatabaseOperations_HEADERS = \
	DatabaseOperations.h

DatabaseOperations_PRINCIPAL_CLASS = DatabaseOperationsComponent

DatabaseOperations_LANGUAGES = English German

DatabaseOperations_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


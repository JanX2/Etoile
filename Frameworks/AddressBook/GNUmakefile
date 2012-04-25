include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = AddressBook
else
FRAMEWORK_NAME = AddressBook
endif
VERSION = 0.1

$(FRAMEWORK_NAME)_HEADER_FILES_DIR = .

$(FRAMEWORK_NAME)_HEADER_FILES = $(wildcard *.h)

$(FRAMEWORK_NAME)_OBJC_FILES = $(wildcard *.m)

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include ../../etoile.make
-include etoile.make
-include ../../documentation.make

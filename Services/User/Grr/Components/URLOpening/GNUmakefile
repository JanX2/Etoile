

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = URLOpening
BUNDLE_EXTENSION = .grrc

$(BUNDLE_NAME)_STANDARD_INSTALL=no

URLOpening_OBJC_FILES = \
	URLOpeningComponent.m \

URLOpening_HEADERS = \
	URLOpeningComponent.h \


URLOpening_PRINCIPAL_CLASS = URLOpeningComponent

URLOpening_LANGUAGES = English German

URLOpening_LOCALIZED_RESOURCE_FILES = \
	URLOpeningComponent.gorm \
	Localizable.strings \

URLOpening_RESOURCE_FILES = \
	Resources/WebBrowser.tiff \

ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble




include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Fonts
BUNDLE_EXTENSION = .grrc

$(BUNDLE_NAME)_STANDARD_INSTALL=no

Fonts_OBJC_FILES = \
	FontsComponent.m \
	FontBox.m \

Fonts_HEADERS = \
	FontsComponent.h \
	FontBox.h \

Fonts_PRINCIPAL_CLASS = FontsComponent

Fonts_LANGUAGES = English German

Fonts_LOCALIZED_RESOURCE_FILES = \
	FontsComponent.gorm \

Fonts_RESOURCE_FILES = \
	Resources/Fonts.tiff \

ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


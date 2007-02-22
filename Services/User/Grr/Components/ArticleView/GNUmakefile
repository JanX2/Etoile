

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = ArticleView
BUNDLE_EXTENSION = .grrc

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

ArticleView_OBJC_FILES = \
	ArticleTextViewPlugin.m \
	NSString+TolerantHTML.m \

ArticleView_HEADERS = \
	ArticleTextViewPlugin.h \
	NSString+TolerantHTML.h \

ArticleView_PRINCIPAL_CLASS = ArticleTextViewPlugin

ArticleView_LANGUAGES = English German

ArticleView_LOCALIZED_RESOURCE_FILES = \
	ArticleTextViewPlugin.gorm \
	Localizable.strings \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


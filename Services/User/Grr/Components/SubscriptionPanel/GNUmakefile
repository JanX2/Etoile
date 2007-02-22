

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = SubscriptionPanel
BUNDLE_EXTENSION = .grrc

BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/Grr

SubscriptionPanel_OBJC_FILES = \
	SubscriptionPanel.m \

SubscriptionPanel_HEADERS = \
	SubscriptionPanel.h \

SubscriptionPanel_PRINCIPAL_CLASS = SubscriptionPanelController

SubscriptionPanel_LANGUAGES = English German

SubscriptionPanel_LOCALIZED_RESOURCE_FILES = \
	SubscriptionPanel.gorm \
	Localizable.strings \


ADDITIONAL_OBJCFLAGS = -Wall -Wno-import

ADDITIONAL_INCLUDE_DIRS += -I../..

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble


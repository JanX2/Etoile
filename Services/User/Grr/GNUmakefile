include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.6.1
PACKAGE_NAME = Grr
APP_NAME = Grr
Grr_APPLICATION_ICON = rssreader.png
Grr_STANDARD_INSTALL = yes

Grr_OBJC_FILES = \
	RSSReaderService.m \
	PaneController.m \
	LogPane.m \
	PreferencePane.m \
	FontPreferencePane.m \
	CKTableView.m \
	TagHandler.m \
	CodeParser.m \
	RenderHandler.m \
	FeedBookmarkView.m \
	Global.m \
	FetchingProgressManager.m \
	SubscriptionPanelController.m \
	ContentTextView.m \
	FeedList.m \
	RSSReaderFeed.m \
	MainWindow.m \
	Controller.m \
	main.m 

ifeq ($(FOUNDATION_LIB), apple)
else
Grr_OBJC_FILES += OpenURL.m
endif

Grr_GUI_LIBS += -lCollectionKit -lBookmarkKit -lPaneKit

Grr_RESOURCE_FILES += \
	Resources/rssreader.png \
	Resources/rssreader.icns \
	Resources/rssreader-working.png \
	Resources/rdf.tiff \
	Resources/xml.tiff \
	Resources/rss.tiff \
	GrrInfo.plist

Grr_LANGUAGES = \
	English

Grr_LOCALIZED_RESOURCE_FILES += \
	Localizable.strings

ifeq ($(FOUNDATION_LIB), apple)
Grr_LOCALIZED_RESOURCE_FILES += \
	FontPreferencePane.nib \
	PreferencePane.nib \
	MainMenu.nib \
	AddFeedPanel.nib 
Grr_MAIN_MODEL_FILE = MainMenu.nib
else
Grr_LOCALIZED_RESOURCE_FILES += \
	FontPreferencePane.gorm \
	PreferencePane.gorm\
	MainMenu.gorm \
	AddFeedPanel.gorm 
Grr_MAIN_MODEL_FILE = MainMenu.gorm
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
#include ../../../etoile.make
-include GNUmakefile.postamble

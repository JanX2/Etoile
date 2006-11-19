include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.7
PACKAGE_NAME = Mollusk
APP_NAME = Mollusk
Mollusk_APPLICATION_ICON = rssreader.png
Mollusk_STANDARD_INSTALL = yes

Mollusk_OBJC_FILES = \
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
Mollusk_OBJC_FILES += OpenURL.m
endif

Mollusk_GUI_LIBS += -lCollectionKit -lBookmarkKit -lPaneKit

Mollusk_RESOURCE_FILES += \
	Resources/rssreader.png \
	Resources/rssreader.icns \
	Resources/rssreader-working.png \
	Resources/rdf.tiff \
	Resources/xml.tiff \
	Resources/rss.tiff \
	MolluskInfo.plist

Mollusk_LANGUAGES = \
	English

Mollusk_LOCALIZED_RESOURCE_FILES += \
	Localizable.strings

ifeq ($(FOUNDATION_LIB), apple)
Mollusk_LOCALIZED_RESOURCE_FILES += \
	FontPreferencePane.nib \
	PreferencePane.nib \
	MainMenu.nib \
	AddFeedPanel.nib 
Mollusk_MAIN_MODEL_FILE = MainMenu.nib
else
Mollusk_LOCALIZED_RESOURCE_FILES += \
	FontPreferencePane.gorm \
	PreferencePane.gorm\
	MainMenu.gorm \
	AddFeedPanel.gorm 
Mollusk_MAIN_MODEL_FILE = MainMenu.gorm
endif

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
include ../../../etoile.make
-include GNUmakefile.postamble

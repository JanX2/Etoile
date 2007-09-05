include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = NewsStand

NewsStand_SUBPROJECTS = \
	SQLite3 \
	NewsParser \
	Extensions

NewsStand_OBJC_FILES = \
	ActivityLog.m                   ImageAndTextCell.m \
	ActivityViewer.m                Import.m \
	AdvancedPreferences.m           InfoWindow.m \
	AppController.m \
	AppearancesPreferences.m        Message.m \
	ArticleController.m             MessageListView.m \
	ArticleFilter.m                 NewGroupFolder.m \
	ArticleListView.m               NewPreferencesController.m \
	ArticleRef.m                    NewSubscription.m \
	ArticleView.m \
	AsyncConnection.m \
	BackTrackArray.m                Preferences.m \
	RefreshManager.m \
	RenameFolder.m \
	SNDisclosableView.m \
	Constants.m                     SNDisclosureButton.m \
	Criteria.m                      SearchFolder.m \
	Database.m                      SearchString.m \
	DownloadManager.m \
	DownloadWindow.m \
	EmptyTrashWarning.m \
	Export.m \
	FeedCredentials.m \
	Field.m                         TreeNode.m \
	Folder.m                        UnifiedDisplayView.m \
	FolderView.m                    ViennaApp.m \
	FoldersTree.m \
	GeneralPreferences.m            main.m \
	HelperFunctions.m \
	TextWebView.m

#NewsStand_OBJC_FILES += \
	TabbedWebView.m

NewsStand_RESOURCE_FILES = \
	Resources/*.icns \
	Resources/*.tiff \
	Resources/*.plist \
	Styles \
	NewsStandInfo.plist

NewsStand_LANGUAGES = \
	English

NewsStand_LOCALIZED_RESOURCE_FILES = \
	ActivityViewer.nib              GroupFolder.strings \
	AdvancedPreferences.nib         InfoPlist.strings \
	AdvancedPreferences.strings     InfoWindow.nib \
	AppearancesPreferences.nib      InfoWindow.strings \
	AppearancesPreferences.strings  Localizable.strings \
	MainMenu.strings \
	EmptyTrashWarning.nib \
	EmptyTrashWarning.strings \
	FeedCredentials.nib             RSSFeed.nib \
	FeedCredentials.strings         RSSFeed.strings \
	GeneralPreferences.nib \
	GeneralPreferences.strings      SearchFolder.nib \
	SearchFolder.strings \
	GroupFolder.nib


ADDITIONAL_OBJCFLAGS += \
	-ISQLite3 \
	-INewsParser \
	-IExtensions \
	-fobjc-exceptions

ADDITIONAL_LDFLAGS += \
	-lETXML \
	`curl-config --libs`

ifeq ($(FOUNDATION_LIB), apple)
#ADDITIONAL_LDFLAGS += \
#	-framework WebKit
NewsStand_LOCALIZED_RESOURCE_FILES += MainMenu.nib
NewsStand_MAIN_MODEL_FILE = MainMenu.nib
else
#ADDITIONAL_LDFLAGS += \
#	-lSimpleWebKit
#NewsStand_LOCALIZED_RESOURCE_FILES += MainMenu.gorm
#NewsStand_MAIN_MODEL_FILE = MainMenu.gorm
endif
ADDITIONAL_OBJCFLAGS += -DNO_WEBKIT

include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


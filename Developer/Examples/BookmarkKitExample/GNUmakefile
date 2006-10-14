include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = BookmarkKit

APP_NAME = BookmarkManager

BookmarkManager_OBJC_FILES = \
	BKOutlineView.m \
	BKTableView.m \
	BookmarkManagerModel.m \
	BookmarkManagerView.m \
	BookmarkManager.m \
	main.m 

BookmarkManager_GUI_LIBS += -lBookmarkKit

BookmarkManager_RESOURCE_FILES = \
	MainMenu.gorm 

BookmarkManager_LANGUAGES = \
	English

BookmarkManager_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings

BookmarkManager_MAIN_MODEL_FILE = MainMenu.gorm

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../../etoile.make


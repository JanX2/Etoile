include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = BookmarkKit

APP_NAME = BookmarkManager

BookmarkManager_OBJC_FILES = \
	BKTableView.m \
	BookmarkManagerModel.m \
	BookmarkManagerView.m \
	BookmarkManager.m \
	main.m 

BookmarkManager_GUI_LIBS += -lBookmarkKit

ifeq ($(FOUNDATION_LIB), apple)
BookmarkManager_RESOURCE_FILES = \
	MainMenu.nib
BookmarkManager_MAIN_MODEL_FILE = MainMenu.nib
BookmarkManager_GUI_LIBS += -lCollectionKit
else
BookmarkManager_RESOURCE_FILES = \
	MainMenu.gorm 
BookmarkManager_MAIN_MODEL_FILE = MainMenu.gorm
endif

BookmarkManager_LANGUAGES = \
	English

BookmarkManager_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings


include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../../etoile.make


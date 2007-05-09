
include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Babbler

Babbler_OBJC_FILES = \
	main.m \
	Controller.m \
	StreamPanel.m \
	Player.m

Babbler_RESOURCE_FILES = \
	BabblerInfo.plist 

Babbler_LANGUAGES = \
        English

#Babbler_LOCALIZED_RESOURCE_FILES += \
#        Localizable.strings

Babbler_LOCALIZED_RESOURCE_FILES += \
        StreamPanel.gorm \
	Player.gorm \
        MainMenu.gorm

Babbler_MAIN_MODEL_FILE = MainMenu.gorm

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -lXWindowServerKit -lMultimediaKit

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

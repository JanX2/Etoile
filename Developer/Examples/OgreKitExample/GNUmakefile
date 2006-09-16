include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = FindPanelExample

ADDITIONAL_INCLUDE_DIRS += -I..
#ADDITIONAL_CFLAGS += `onig-config --cflags`
#ADDITIONAL_LIB_DIRS += `onig-config --libs`
ADDITIONAL_GUI_LIBS += -lOgreKit 

FindPanelExample_OBJC_FILES = \
	Delegate.m \
	main.m

FindPanelExample_MAIN_MODEL_FILE = FindPanelExample.gorm
FindPanelExample_RESOURCE_FILES = FindPanelExample.gorm

include $(GNUSTEP_MAKEFILES)/application.make

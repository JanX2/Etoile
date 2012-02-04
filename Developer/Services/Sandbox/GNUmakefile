include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Sandbox

$(APP_NAME)_OBJC_FILES = \
	main.m \
	Controller.m

$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm

$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm

$(APP_NAME)_GUI_LIBS += -lSourceCodeKit -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Test

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)

$(APP_NAME)_MAIN_MODEL_FILE = MainMenu.gorm
$(APP_NAME)_RESOURCE_FILES = MainMenu.gorm

# To build an Etoile test app, uncomment the lines below
#$(APP_NAME)_CPPFLAGS += -DETOILEAPP
#$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
#$(APP_NAME)_GUI_LIBS = -lEtoileUI -lEtoileFoundation -lCoreObject
#$(APP_NAME)_INCLUDE_DIRS += -I`pg_config --includedir`
#$(APP_NAME)_LIBRARY_DIRS += -L`pg_config --libdir`

include $(GNUSTEP_MAKEFILES)/application.make


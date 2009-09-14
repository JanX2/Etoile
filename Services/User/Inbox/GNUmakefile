include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Inbox

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_RESOURCE_FILES = $(APP_NAME)-Info.plist 
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lEtoileUI -lRSSKit -lPantomime

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

# Reset additional_obj flags so we don't inherit Werror
ADDITIONAL_OBJCFLAGS = -Wall



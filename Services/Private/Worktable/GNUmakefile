include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99 -DCOREOBJECT
ADDITIONAL_OBJCFLAGS += -I. -DCOREOBJECT

APP_NAME = Worktable

$(APP_NAME)_OBJC_FILES = $(wildcard *.m)

$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_RESOURCE_FILES = $(APP_NAME)Info.plist

$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lCoreObject -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

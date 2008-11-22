include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I.  -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format -g

APP_NAME = OverlayShelf
$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_RESOURCE_FILES = $(wildcard *.st) $(wildcard *.jpg) stamp.png
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lCoreObject -lEtoileUI -lSmalltalkKit -lSmalltalkSupport -lLanguageKit -lScriptKit

# CoreObject
ADDITIONAL_INCLUDE_DIRS += -I`pg_config --includedir`
ADDITIONAL_LIB_DIRS += -L`pg_config --libdir`

include $(GNUSTEP_MAKEFILES)/application.make
#

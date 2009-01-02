include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = ShareApp

ShareApp_OBJC_FILES = \
	AppController.m \
	main.m


ifeq ($(FOUNDATION_LIB), apple)
	ShareApp_LOCALIZED_RESOURCE_FILES = \
		MainMenu.nib 

	ADDITIONAL_LDFLAGS = -framework ShareKit
else
endif

include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


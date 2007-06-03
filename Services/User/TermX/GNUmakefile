include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = TermX

TermX_OBJC_FILES = \
	TXCursor.m \
	TerminalView.m \
	TerminalController.m \
	TTY.m \
	AppController.m \
	main.m

TermX_C_FILES = \
	256colors.c 

TermX_RESOURCE_FILES = TermXInfo.plist

TermX_LANGUAGES = English

ifeq ($(FOUNDATION_LIB), apple)
	TermX_LOCALIZED_RESOURCE_FILES = \
		MainMenu.nib  \
		TerminalWindow.nib 
else
	TermX_LOCALIZED_RESOURCE_FILES = \
		MainMenu.nib  \
		TerminalWindow.gorm
endif

ifeq ($(findstring freebsd, $(GNUSTEP_TARGET_OS)), freebsd)
	ADDITIONAL_OBJCFLAGS += -DFREEBSD
endif

ifeq ($(findstring openbsd, $(GNUSTEP_TARGET_OS)), openbsd)
	ADDITIONAL_OBJCFLAGS += -DOPENBSD
endif

ifeq ($(findstring darwin, $(GNUSTEP_TARGET_OS)), darwin)
	ADDITIONAL_OBJCFLAGS += -DDARWIN
endif

ifeq ($(findstring gnu, $(GNUSTEP_TARGET_OS)), gnu)
	ADDITIONAL_OBJCFLAGS += -DLINUX
	ADDITIONAL_LDFLAGS += -lutil
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble


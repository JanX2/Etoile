include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#

VERSION = 0.1
PACKAGE_NAME = StepChat
APP_NAME = StepChat
StepChat_APPLICATION_ICON = 

#
# Resource files
#
StepChat_LANGUAGES = English

StepChat_RESOURCE_FILES = \
	StepChatInfo.plist \
	Resources/StepChat.tiff

StepChat_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.nib\
	  AccountBox.nib\
	  PasswordBox.nib
ifeq ($(FOUNDATION_LIB), apple)
StepChat_LOCALIZED_RESOURCE_FILES += \
	  MessageWindow.nib\
	  RosterWindow.nib
else
StepChat_LOCALIZED_RESOURCE_FILES += \
	  MessageWindow.gorm\
	  RosterWindow.gorm
endif

#
# Class files
#
StepChat_OBJC_FILES = \
	AddContactWindowController.m\
	ChatLogMenuController.m\
	CustomPresenceWindowController.m\
	HideMenuController.m\
	JabberApp.m\
	MessageWindowController.m\
	NSTextView+ClickableLinks.m\
	AccountWindowController.m\
	PasswordWindowController.m\
	PreferenceWindowController.m\
	PresenceMenuController.m\
	PresenceLogController.m\
	RosterController.m\
	TRUserDefaults.m\
	XMLLog.m\
	main.m

ADDITIONAL_LDFLAGS += -lEtoileXML -lXMPPKit -lAddresses -lssl -lcrypto -g \
	$(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)
ADDITIONAL_OBJCFLAGS += -werror -g
ADDITIONAL_OBJCFLAGS = -DGNUSTEP -DNO_ATTRIBUTED_TITLES -std=c99 -Wno-import

#
# Makefiles
#
include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make

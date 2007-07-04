include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
SUBPROJECTS = TRXML xmpp
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
	  PasswordBox.nib\
	  RosterWindow.nib
ifeq ($(FOUNDATION_LIB), apple)
StepChat_LOCALIZED_RESOURCE_FILES += \
	  MessageWindow.nib
else
StepChat_LOCALIZED_RESOURCE_FILES += \
	  MessageWindow.gorm
endif

#
# Header files
#
StepChat_HEADER_FILES = 

#
# Class files
#
StepChat_OBJC_FILES = \
	AddContactWindowController.m\
	ChatLogMenuController.m\
	CustomPresenceWindowController.m\
	GlobalPreferences.m\
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

ADDITIONAL_LDFLAGS += -lTRXML -lXMPP -lssl -lcrypto -lAddresses -g
ADDITIONAL_OBJCFLAGS += -werror -g
ADDITIONAL_LIB_DIRS += -LTRXML/$(GNUSTEP_OBJ_DIR) -Lxmpp/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_OBJCFLAGS = -DGNUSTEP -DNO_ATTRIBUTED_TITLES -std=c99 -Wno-import -Ixmpp -ITRXML

#
# Makefiles
#
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../etoile.make
include $(GNUSTEP_MAKEFILES)/application.make

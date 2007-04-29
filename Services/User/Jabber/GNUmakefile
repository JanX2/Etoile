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

StepChat_RESOURCE_FILES = StepChatInfo.plist

StepChat_LOCALIZED_RESOURCE_FILES = \
	  MainMenu.nib\
	  MessageWindow.nib\
	  AccountBox.gorm\
	  PasswordBox.nib\
	  RosterWindow.nib

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
	AccountWindowController.m\
	PasswordWindowController.m\
	PreferenceWindowController.m\
	PresenceMenuController.m\
	RosterController.m\
	TRUserDefaults.m\
	XMLLog.m\
	main.m

ADDITIONAL_LDFLAGS += -lTRXML -lXMPP -lssl -lcrypto -lAddresses
ADDITIONAL_OBJCFLAGS += -werror -g
ADDITIONAL_LIB_DIRS += -LTRXML/$(GNUSTEP_OBJ_DIR) -Lxmpp/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_OBJCFLAGS = -DGNUSTEP -DNO_ATTRIBUTED_TITLES -std=c99 -Wno-import -Ixmpp -ITRXML

#
# Makefiles
#
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

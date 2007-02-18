include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
PACKAGE_NAME = StepChat
APP_NAME = StepChat
StepChat_APPLICATION_ICON = 
StepChat_SUBPROJECTS = TRXML xmpp
ADDITIONAL_LDFLAGS += -lTRXML -lxmpp


#
# Resource files
#
StepChat_RESOURCE_FILES = \
GNUstep/MainMenu.gorm\
GNUstep/Info-gnustep.plist

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
					PasswordWindowController.m\
					PreferenceWindowController.m\
					PresenceMenuController.m\
					RosterController.m\
					TRUserDefaults.m\
					XMLLog.m\
					main.m

ADDITIONAL_OBJCFLAGS = -DGNUSTEP -DNO_ATTRIBUTED_TITLES -std=c99 -Wno-import -Ixmpp -ITRXML

#
# Makefiles
#
-include GNUmakefile.preamble
#include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

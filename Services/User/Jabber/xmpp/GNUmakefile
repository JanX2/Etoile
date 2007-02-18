include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = XMPP
XMPP_OBJCFLAGS += -g -std=c99 -DGNUSTEP 

ADDITIONAL_INCLUDE_DIRS += -I../TRXML/

XMPP_OBJC_FILES = \
					ChatLog.m\
					CompareHack.m\
					Conversation.m\
					DefaultHandler.m\
					Dispatcher.m\
					GroupChat.m\
					Iq.m\
					IqStanzaFactory.m\
					JID.m\
					JabberIdentity.m\
					JabberPerson.m\
					JabberResource.m\
					JabberRootIdentity.m\
					Message.m\
					MessageStanzaFactory.m\
					NSData+Base64.m\
					PresenceStanzaFactory.m\
					Presence.m\
					Query_jabber_iq_roster.m\
					Roster.m\
					RosterGroup.m\
					StanzaFactory.m\
					StreamFeatures.m\
					Timestamp.m\
					XMPPAccount.m\
					XMPPConnection.m\
					jabber_iq_roster.m\
					query_jabber_iq_auth.m
# Not currently compiled files:
#					Capabilities.m\
#					ServiceDiscovery.m\
#					TRXMLXHTML-IMParser.m\

XMPP_HEADER_FILES = \
					Capabilities.h\
					ChatLog.h\
					CompareHack.h\
					Conversation.h\
					DefaultHandler.h\
					Dispatcher.h\
					GroupChat.h\
					Iq.h\
					IqStanzaFactory.h\
					JID.h\
					JabberIdentity.h\
					JabberPerson.h\
					JabberResource.h\
					JabberRootIdentity.h\
					Message.h\
					MessageStanzaFactory.h\
					NSData+Base64.h\
					PresenceStanzaFactory.h\
					Presence.h\
					Query_jabber_iq_roster.h\
					Roster.h\
					RosterGroup.h\
					ServiceDiscovery.h\
					StanzaFactory.h\
					StreamFeatures.h\
					TRXMLXHTML-IMParser.h\
					Timestamp.h\
					XMPPAccount.h\
					XMPPConnection.h\
					jabber_iq_roster.h\
					query_jabber_iq_auth.h\

include $(GNUSTEP_MAKEFILES)/library.make

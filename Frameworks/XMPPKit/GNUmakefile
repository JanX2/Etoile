include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = XMPPKit
DOCUMENT_NAME = ${FRAMEWORK_NAME}

${FRAMEWORK_NAME}_VERSION = 0.1

LIBRARIES_DEPEND_UPON += -lEtoileFoundation -lAddresses -lssl -lcrypto \
	$(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

${FRAMEWORK_NAME}_OBJCFLAGS += -g -std=c99
${FRAMEWORK_NAME}_LDFLAGS += -g

${DOCUMENT_NAME}_AGSDOC_FLAGS += -MakeFrames YES

${FRAMEWORK_NAME}_OBJC_FILES = \
					ABPerson+merging.m\
					ChatLog.m\
					CompareHack.m\
					Conversation.m\
					DefaultHandler.m\
					Dispatcher.m\
					DiscoItems.m\
					DiscoInfo.m\
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
					Stanza.m\
					StreamFeatures.m\
					Timestamp.m\
					XMPPAccount.m\
					XMPPConnection.m\
					XMPPError.m\
					XMPPvCard.m\
					jabber_iq_roster.m\
					query_jabber_iq_auth.m\
					ServiceDiscovery.m\

${FRAMEWORK_NAME}_HEADER_FILES = \
					ChatLog.h\
					CompareHack.h\
					Conversation.h\
					DefaultHandler.h\
					Dispatcher.h\
					DiscoItems.h\
					DiscoInfo.h\
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
					Stanza.h\
					StreamFeatures.h\
					Timestamp.h\
					XMPPAccount.h\
					XMPPConnection.h\
					XMPPError.h\
					XMPPvCard.h\
					jabber_iq_roster.h\
					query_jabber_iq_auth.h

${DOCUMENT_NAME}_AGSDOC_FILES = ${${FRAMEWORK_NAME}_HEADER_FILES}

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
ifeq ($(doc), yes)
# NOTE: Made optional because broken with gnustep-base 1.15.3:
#Generating reference documentation...
#autogsdoc: Uncaught exception NSInvalidArgumentException, reason: GSMutableSet(instance) does not recognize #removeObjectForKey:
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

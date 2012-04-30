include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = XMPPKit
DOCUMENT_NAME = ${FRAMEWORK_NAME}

${FRAMEWORK_NAME}_VERSION = 0.2

LIBRARIES_DEPEND_UPON += -lEtoileFoundation -lEtoileXML -lAddresses \
        $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

${FRAMEWORK_NAME}_OBJCFLAGS += -g -std=c99 -fobjc-arc
${FRAMEWORK_NAME}_LDFLAGS += -g

${DOCUMENT_NAME}_AGSDOC_FLAGS += -MakeFrames YES

${FRAMEWORK_NAME}_OBJC_FILES = \
                                        ABPerson+merging.m\
                                        XMPPChatLog.m\
                                        CompareHack.m\
                                        XMPPConversation.m\
                                        XMPPDefaultHandler.m\
                                        XMPPDispatcher.m\
                                        XMPPDiscoItems.m\
                                        XMPPDiscoInfo.m\
                                        XMPPGroupChat.m\
                                        XMPPInfoQueryStanza.m\
                                        XMPPInfoQueryStanzaFactory.m\
                                        JID.m\
                                        XMPPIdentity.m\
                                        XMPPPerson.m\
                                        XMPPResource.m\
                                        XMPPRootIdentity.m\
                                        XMPPMessage.m\
                                        XMPPMessageStanzaFactory.m\
                                        NSAttributedString+HTML-IM.m\
                                        XMPPPresenceStanzaFactory.m\
                                        XMPPPresence.m\
                                        XMPPQueryRosterHandler.m\
                                        XMPPRoster.m\
                                        XMPPRosterGroup.m\
                                        XMPPStanzaFactory.m\
                                        XMPPStanza.m\
                                        XMPPStreamFeatures.m\
                                        XMPPTimestamp.m\
                                        XMPPAccount.m\
                                        XMPPConnection.m\
                                        XMPPError.m\
                                        XMPPObjectStore.m\
                                        XMPPvCard.m\
                                        XMPPServiceDiscovery.m\

${FRAMEWORK_NAME}_HEADER_FILES = \
                                        XMPPChatLog.h\
                                        CompareHack.h\
                                        XMPPConversation.h\
                                        XMPPDefaultHandler.h\
                                        XMPPDispatcher.h\
                                        XMPPDiscoItems.h\
                                        XMPPDiscoInfo.h\
                                        XMPPGroupChat.h\
                                        XMPPInfoQueryStanza.h\
                                        XMPPInfoQueryStanzaFactory.h\
                                        JID.h\
                                        XMPPIdentity.h\
                                        XMPPPerson.h\
                                        XMPPResource.h\
                                        XMPPRootIdentity.h\
                                        XMPPMessage.h\
                                        XMPPMessageStanzaFactory.h\
                                        NSAttributedString+HTML-IM.h\
                                        XMPPPresenceStanzaFactory.h\
                                        XMPPPresence.h\
                                        XMPPQueryRosterHandler.h\
                                        XMPPRoster.h\
                                        XMPPRosterGroup.h\
                                        XMPPServiceDiscovery.h\
                                        XMPPStanzaFactory.h\
                                        XMPPStanza.h\
                                        XMPPStreamFeatures.h\
                                        XMPPTimestamp.h\
                                        XMPPAccount.h\
                                        XMPPConnection.h\
                                        XMPPError.h\
                                        XMPPObjectStore.h\
                                        XMPPvCard.h

${DOCUMENT_NAME}_AGSDOC_FILES = ${${FRAMEWORK_NAME}_HEADER_FILES}

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
ifeq ($(doc), yes)
# NOTE: Made optional because broken with gnustep-base 1.15.3:
#Generating reference documentation...
#autogsdoc: Uncaught exception NSInvalidArgumentException, reason: GSMutableSet(instance) does not recognize #removeObjectForKey:
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

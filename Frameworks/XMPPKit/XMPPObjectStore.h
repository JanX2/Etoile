/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */
#import <Foundation/Foundation.h>
#import <EtoileXML/ETXMLNullHandler.h>
#import <EtoileSerialize/ETObjectStore.h>

@class ETXMLWriter,ETXMLParser,ETUUID,Conversation;
@protocol ETSerialObjectStore;

/**
 * The XMPPObjectStore allows CoreObjects to be serialized via an XMPP
 * connection.
 */
@interface XMPPObjectStore: ETXMLNullHandler <ETSerialObjectStore>
{
	/** The XML writer attached to the store. */
	ETXMLWriter *writer;

	/** The version being serialized/deserialized */
	NSUInteger version;

	/** The branch being serialized/deserialized. */
	NSString *branch;

	/**
	 * The remote process that is responsible for handling deserializations.
	 */
	id proxy;

	/**
	 * The deserializer handling the store.
	 */
	id deserializer;

	/**
	 * The conversation the store is attached to. This needs to be tracked in
	 * order to finish the message that forms the root of the XML tree produced
	 * by the serializer.
	 */
	id conversation;

	/**
	 * The UUID of the object in the store.
	 */
	ETUUID *uuid;

	/**
	 * The name of the serialization backend used, if it can be derived.
	 */
	NSString *backendName;

	/**
	 * A buffer for data that might arrive in a non-XML format.
	 */
	 NSMutableData *buffer;
}


/**
 * Designated initializer to set up a fully fledge store.
 */
- (id)initWithXMLParser: (ETXMLParser*)aParser
             XMLWriter: (ETXMLWriter*)aWriter
                parent: (id<ETXMLParserDelegate>)aParent
                   key: (id)aKey
        inConversation: (Conversation*)aConversation;

/**
 * Initializer to be used if the store is used only for writing.
 */
- (id)initWithXMLWriter: (ETXMLWriter*)aWriter
         inConversation: (Conversation*)aConversation;

/**
 * Starts sending out the object on the stream, indicating its UUID and the name
 * the handling application has registered with the DO nameservice.
 * NOTE: After calling this method, the Conversation cannot be used to send
 * other data until the requesting process has finished serializing.
 */
- (void)beginObjectWithUUID: (ETUUID*)uuid
             andApplication: (NSString*)registeredName;

// Methods used by the XML serializer:

/**
 * Returns the XML writer attached to the store.
 */
- (ETXMLWriter*)xmlWriter;

/**
 * Returns whether the XML writer will store the XML itself so that the
 * -writeBytes:count: method of the store does not need to be called.
 */
- (BOOL)xmlWriterWillStore;

// Methods used by the XML deserializer:

/**
 * Returns the XML parser attached to the store.
 */
- (ETXMLParser*)xmlParser;

/**
 * Returns whether the store's XML parser can be used to deserialize off the
 * stream.
 */
- (BOOL)xmlParserWillRead;

// Methods for the ETSerialObjectStore protocol:

/**
 * Returns the branch that is the parent of the specified branch.
 */
- (NSString*)parentOfBranch: (NSString*)aBranch;

/**
 * Returns true if the specified branch exists.
 */
- (BOOL)isValidBranch: (NSString*)aBranch;

/**
 * Start a new version in the specified branch.  Subsequent data will be
 * written to this branch.
 */
- (void)startVersion: (unsigned)aVersion
        inBranch: (NSString*)aBranch;

/**
 * Writes the specified data to the store.
 */
- (void)writeBytes: (unsigned char*)bytes
             count: (unsigned)count;

/**
 * Interface for an object store that allows serial data to be written to it.
 */
- (NSData*)dataForVersion: (unsigned)aVersion
                 inBranch: (NSString*)aBranch;

/**
 * Returns the amount of data written so far in this version. NOTE: Will always
 * return 0.
 */
- (unsigned)size;

/**
 * Guarantees that sending the data is finished by closing the "coreobject"- and
 * "message"-tags of the store.
 */
- (void)commit;

/**
 * Returns the version currently being written, or the last version to be
 * written if the version is finalised.
 */
- (unsigned)version;

/**
 * Returns the branch currently being written, or the last branch to be
 * written if the version is finalised.
 */
- (NSString*)branch;

/**
 * Create a new branch from the specified parent branch.
 */
- (void)createBranch: (NSString*)newBranch
                from: (NSString*)oldBranch;

@end

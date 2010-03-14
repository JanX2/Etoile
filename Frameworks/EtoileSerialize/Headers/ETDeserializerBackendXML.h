/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileXML/ETXMLNullHandler.h>
#import <EtoileSerialize/ETDeserializerBackend.h>
#import <EtoileSerialize/ETUtility.h>
#import <EtoileXML/ETXMLParserDelegate.h>

@class ETDeserializer,ETXMLParser,ETDeserializableobjectsXMLNode;
/**
 * Deserializer backend for restoring object graphs serialized in XML format.
 */
@interface ETDeserializerBackendXML : ETXMLNullHandler <ETDeserializerBackend> {
	/** The data store */
	id store;
	/** The name of the current branch. */
	NSString * branch;
	/** The XML data to parse when the parser next runs. */
	NSData *buffer;
	/** Deserializer to use for reconstructing objects. */
	ETDeserializer * deserializer;
	/** The principal object of the stored object graph. */
	CORef principalObjectRef;
	/** The class of the principal object. */
	Class principalObjectClass;
}

// Deserializer backend methods
- (BOOL) deserializeFromStore: (id)aStore;
- (BOOL) deserializeFromData: (NSData *)aData;
- (BOOL) setBranch: (NSString *)aBranch;
- (int) setVersion: (int)aVersion;
- (void) setDeserializer: (id)aDeserializer;
- (void) dealloc;
- (CORef) principalObject;
- (char*) classNameOfPrincipalObject;
- (BOOL) deserializeObjectWithID: (CORef)aReference;

// Methods used by the deserialization handlers:
- (void) setPrincipalObjectRef: (CORef) aRef;
- (void) setPrincipalObjectClass: (NSString *)className;
@end

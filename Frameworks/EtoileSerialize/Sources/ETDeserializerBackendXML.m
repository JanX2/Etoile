/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#include <stdio.h>
#import "ETDeserializerBackendXML.h"
#import "ETXMLDeserializationHandler.h"
#import "ETDeserializer.h"
#import "ETObjectStore.h"
#import "ETUtility.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileXML/ETXMLParser.h>
#import <EtoileXML/ETXMLParserDelegate.h>

/**
 * XML backend for the deserializer.
 */
@implementation ETDeserializerBackendXML

- (id) init
{
	SUPERINIT
	buffer = nil;
	principalObjectRef = 0;
	principalObjectClass = Nil;
	parser = [[ETXMLParser alloc] initWithContentHandler: self];
	return self;
}

/**
 * Loads the URL and prepares to deserialize it.
 */
- (BOOL) deserializeFromStore:(id)aStore
{
	if (![aStore conformsToProtocol:@protocol(ETSerialObjectStore)])
	{
		return NO;
	}
	ASSIGN(store, aStore);
	return YES;
}

/**
 * Parses the data to deserialize the object graph.
 */
- (BOOL) deserializeByParsingData: (NSData*)someData
{
	NSString *rawXML = [[[NSString alloc] initWithBytes: [someData bytes]
	                                             length: [someData length]
	                                           encoding: NSUTF8StringEncoding] autorelease];
		
	return [parser parseFromSource: rawXML];
}

/**
 * Places the data that shall be deserialized in a buffer. Can also be used to
 * append additional data from a stream.
 */
- (BOOL) deserializeFromData:(NSData*)aData
{
	if (nil == aData)
	{
		return NO;
	}

	if (nil == buffer)
	{
		/*
		 * If the buffer is still nil, the serialization is just getting started
		 * (i.e. aData does not contain some subsequent chunk of data arriving
		 * from a stream). In this case, we retain the aData in the buffer and
		 * start parsing when the deserializer calls
		 * -deserializePrincipalObject.
		 * FIXME: Check whether the data is valid.
		 */
		buffer = [aData retain];
		return YES;
	}
	else
	{
		/*
		 * In this case, the deserialization is already going and we just need
		 * to feed the parser with additional data.
		 */
		return [self deserializeByParsingData: aData];
	}
}

- (BOOL) setBranch:(NSString*)aBranch
{
	if (![store isValidBranch:aBranch])
	{
		return NO;
	}
	ASSIGN(branch, aBranch);
	return YES;
}

- (int) setVersion:(int)aVersion
{
	//FIXME: Get the branch sensibly.
	if ([self deserializeFromData:[store dataForVersion:aVersion inBranch:branch]])
	{
		return aVersion;
	}
	return -1;
}

- (void) setDeserializer:(id)aDeserializer;
{
	ASSIGN(deserializer, aDeserializer);
}

- (void) dealloc
{
	[parser release];
	[buffer release];
	[super dealloc];
}

/**
 * Return the first object. This is set when that object is being parsed.
 */
- (CORef) principalObject
{
	return principalObjectRef;
}

/**
 * Look up the class of the principal object.
 */
- (char*) classNameOfPrincipalObject
{
	return (char*)[NSStringFromClass(principalObjectClass) cStringUsingEncoding: NSASCIIStringEncoding];
}

/**
 * Since we deserialize at parse time, this does nothing.
 */
- (BOOL) deserializeObjectWithID:(CORef)aReference
{
	 return YES;
}

- (BOOL) deserializePrincipalObject
{
	if (0 != principalObjectRef)
	{
		// Because principalObjectRef is set while deserializing, the principal
		// object will already be deserialized under this condition.
		return YES;
	}
	if (nil != buffer)
	{
		BOOL success = [self deserializeByParsingData: buffer];
		[buffer release];
		// We place a data stub in the buffer to signify that we are already
		// deserializing.
		buffer = [[NSData alloc] init];
		return success;
	}
	return NO;
}

/*
 * The ETXMLDeserializationHandler subclasses handle all deserializing, so this
 * does nothing.
 */
- (BOOL) deserializeData:(char*)obj withTypeChar:(char)type
{
	return NO;
}

//Parser delegate methods

- (void) characters: (NSString*) chars
{
	NSDebugLog(@"XML deserializer backend encountered unexpected chars: %@",chars);
}
- (void) startElement: (NSString *)name
           attributes: (NSDictionary*)attributes
{
	if ([name isEqual: @"objects"])
	{
		ETXMLDeserializationHandler *handler =
		[[[ETXMLobjectsDeserializationHandler alloc] initWithXMLParser: parser
		                                                        parent: self
		                                                           key: name] autorelease];
		[handler setDeserializer: deserializer];
		[handler startElement: name attributes: attributes];
	}
	else
	{
		NSDebugLog(@"XML deserializer backend ignoring element '%@'.", name);
	}
}

- (void) endElement: (NSString *)name
{
	//Ignore
}

- (void) setParser: (ETXMLParser *)aParser
{
	[parser autorelease];
	parser = [aParser retain];
}

- (void) setParent: (id)aParent
{
	//Ignore
}

//Setter methods used by deserialization handlers

- (void) setPrincipalObjectClass: (NSString *)className
{
	principalObjectClass = NSClassFromString(className);
}

- (void) setPrincipalObjectRef: (CORef) aRef
{
	principalObjectRef = aRef;
}
@end

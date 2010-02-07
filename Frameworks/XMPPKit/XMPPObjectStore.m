/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */


#import "XMPPObjectStore.h"
#import "Message.h"
#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETUUID.h>
#import <EtoileFoundation/NSData+Hash.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileXML/ETXMLWriter.h>

//These are needed for interface definitions only.
#import <EtoileSerialize/ETObjectStore.h>
#import <EtoileSerialize/ETDeserializer.h>
#import <EtoileSerialize/ETDeserializerBackend.h>

@interface XMPPObjectStoreVersionTag: ETXMLNullHandler
@end

@interface XMPPObjectStoreBranchTag: ETXMLNullHandler
@end

@interface XMPPObjectStoreSerialDataTag: ETXMLNullHandler
@end

static NSDictionary *CHILD_CLASSES;


@implementation XMPPObjectStore

+ (void)initialize
{
	CHILD_CLASSES = D([XMPPObjectStoreVersionTag class], @"version",
	                  [XMPPObjectStoreBranchTag class], @"branch",
                      [XMPPObjectStoreSerialDataTag class], @"serialdata");
	[CHILD_CLASSES retain];

}

- (id)initWithXMLParser: (ETXMLParser *)aParser
              XMLWriter: (ETXMLWriter *)aWriter
                 parent: (id <ETXMLParserDelegate>)aParent
                    key: (id)aKey
         inConversation: (Conversation*)aConversation
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	writer = [aWriter retain];
	conversation = [aConversation retain];
	return self;
}

- (id)initWithXMLParser: (ETXMLParser *)aParser
                 parent: (id <ETXMLParserDelegate>)aParent
                    key: (id)aKey
{
	return [self initWithXMLParser: aParser
                         XMLWriter: nil
                            parent: aParent
                               key: aKey
	                inConversation: nil];
}

- (id)initWithXMLWriter: (ETXMLWriter *)aWriter
         inConversation: (Conversation *)aConversation
{
	return [self initWithXMLParser: nil
                         XMLWriter: aWriter
                            parent: nil
                               key: nil
				    inConversation: aConversation];
}

- (void)setXMLWriter: (ETXMLWriter*)_writer
{
	[writer autorelease];
	writer = [_writer retain];
}

- (void)setDeserializer: (id)aDeserializer
{
	deserializer = aDeserializer;
}
- (void)setConversation: (id)aConversation
{
	// The conversation that the store belongs to. Although it might create the
	// object, it does not retain the store (It is handed out to the serializing
	// process). So it is safe to retain it.
	[conversation autorelease];
	conversation = [aConversation retain];
}

- (void)beginObjectWithUUID: (ETUUID*)objUUID
             andApplication: (NSString *)registeredName
{
	//TODO: Lock the conversation.

	// If we don't have an uuid, we generate one.
	if (nil == objUUID)
	{
		objUUID = [ETUUID UUID];
	}

	// Send an <coreobject> tag on the stream indicating the application and
	// uudi data the receiving side may use for routing the object.
	[writer startElement: @"coreobject"
	          attributes: D(@"http://www.etoileos.com/CoreObject", @"xmlns",
	                       registeredName, @"application",
                           [objUUID stringValue], @"uuid")];
}

- (BOOL)isValidBranch: (NSString*) aBranch
{
	return [branch isEqualToString: aBranch];
}

- (void)startVersion: (unsigned)aVersion inBranch:(NSString*)aBranch
{
	version = (NSUInteger)aVersion;
	[branch autorelease];
	branch = [aBranch retain];
	[writer startAndEndElement: @"branch" cdata: branch];
	[writer startAndEndElement: @"version"
	                     cdata: [[NSNumber numberWithUnsignedInteger: version] stringValue]];
}

- (void)commit
{
	[writer endElement]; //</coreobject>
	[writer endElement]; //</message>
}

- (unsigned)version
{
		    return (unsigned)version;
}

- (NSString*)branch
{
		    return branch;
}

// The writer does not expose to us how much data it has written.
- (unsigned)size
{
	return 0;
}

// This store does not track branches.
- (NSString*)parentOfBranch:(NSString*)aBranch
{
	return nil;
}

// This isn't supported either.
- (void)createBranch:(NSString*)newBranch from:(NSString*)oldBranch;
{
	[branch autorelease];
	branch = [newBranch retain];
}

// We usually don't expect writing any other serialization format than the XML
// one. Still, an XMPP stream can be used to do that. If you really, really want
// it.
- (void)writeBytes: (unsigned char*)bytes
             count: (unsigned)count
{
	NSString* b64 = [[NSData dataWithBytes: bytes length: count] base64String];
	[writer startAndEndElement: @"serialdata"
	                attributes: D(@"unknown", @"backend")
	                     cdata: b64];
}

// This method only works for non-XML deserializers.
- (NSData*)dataForVersion: (unsigned)aVersion
                 inBranch: (NSString*)aBranch
{
	if (aVersion == version && [branch isEqualToString:aBranch])
	{
		return buffer;
	}
	return nil;
}

- (void)startElement: (NSString*)_name
          attributes: (NSDictionary*)_attributes
{
	if ([_name isEqualToString: @"coreobject"])
	{
		depth++;
		uuid = [[ETUUID UUIDWithString: [_attributes objectForKey: @"uuid"]] retain];
		
		proxy = [[NSConnection rootProxyForConnectionWithRegisteredName: [_attributes objectForKey: @"application"]
		                                                           host: nil] retain];
		if (!proxy)
		{
			NSLog(@"Failed to get proxy (%@) for deserialization",[_attributes objectForKey: @"application"]);
		}
		// TODO: If getting the handling application from the nameserver fails
		// this way, we want some way to start it based on UUID and/or
		// identifier.

		if (![proxy conformsToProtocol:@protocol(ETDeserializerVendor)])
		{
			// If the remote end does not support the methods we need to call on
			// it, we don't want to keep the proxy around.
			NSLog(@"Receiving application (%@) does support deserialization.", [_attributes objectForKey: @"application"]);
			[proxy release];
			proxy = nil;
		}
		else
		{
			[proxy setProtocolForProxy: @protocol(ETDeserializerVendor)];
		}
	}
	else if ([_name isEqualToString: @"objects"])
	{
		
		// The <objects> element implies that we are deserializing data in XML
		// format.
		deserializer = [[proxy deserializerWithBackend: @"ETDeserializerBackendXML" 
		                             forObjectWithUUID: uuid
		                                          from: [[(Message*)parent correspondent] jidString]] retain];
		id<ETDeserializerBackend> backend = [(ETDeserializer*)deserializer backend];
		ETXMLNullHandler *handler = nil;	
		if (nil == backend)
		{
			//Ignore if the deserializer backend is not available:
			NSLog(@"No backend, not deserializing");
			handler = [[ETXMLNullHandler alloc] initWithXMLParser: parser
			                                               parent: self
			                                                  key: _name];
		}
		else
		{
			// The deserializer-backend is the new handler.
			// -deserializeFromStore: will make it take over the
			// parsing duties.
			handler = (ETXMLNullHandler *)backend;
			[backend deserializeFromStore: self];
		}
		// The backend will create a handler for the <objects> tag itself.
		[handler startElement: _name attributes: _attributes];
	}
	else 
	{
		ETXMLNullHandler *handler = [(ETXMLNullHandler*)[[CHILD_CLASSES objectForKey: _name] alloc] initWithXMLParser: parser parent: self key: _name];
		if (nil == handler)
		{
			handler = [[ETXMLNullHandler alloc] initWithXMLParser: parser
			                                               parent: self
			                                                  key: _name];
		}
		[handler startElement: _name attributes: _attributes];
	}
}

- (void)endElement: (NSString*)_name
{
	if ([_name isEqualToString: @"coreobject"])
	{
		if ((nil != buffer) && (nil == deserializer))
		{
			// Handle the case that some legacy format was sent over the wire.
			// This uses the backend attribute of the <serialdata> tag.
			// Right now, this will always be "unknown" because object stores
			// are not yet smart enough to tell us about the deserializer
			// backend that is using them to store the object graph. So right
			// now, we'll map "unkown" to "ETDeserializerBackendBinary" because
			// it is the only other deserializer backend as of yet.
			if ((backendName == nil)
			   || [backendName isEqualToString: @"unknown"])
			{
				[backendName autorelease];
				backendName = @"ETDeserializerBackendBinary";
			}
			deserializer = [[proxy deserializerWithBackend: backendName
			                             forObjectWithUUID: uuid
			                                          from: [[(Message*)parent correspondent] jidString]] retain];
		}
		// The XML deserializer does not strictly need setting branch and
		// version but they are needed at least for the binary backend.
		[deserializer setBranch: branch];
		[(ETDeserializer*)deserializer setVersion: version];

		// NOTE: The deserialization process might already be complete when
		// calling -restoreObjectGraph when deserializing was done as the stream
		// arrived. The XML backend is aware of that and won't start all over in
		// this case (cf. -deserializePrincipalObject in
		// ETDeserializerBackendXML). Calling it will then merely make the
		// deserializer finish the deserialization and return the pointer to the
		// object just deserialized.
		id theObject = [deserializer restoreObjectGraph];
		[(id<ETDeserializerVendor>)proxy obtainedObject: theObject
		                                       withUUID: uuid
		                                           from: [[(Message*)parent correspondent] jidString]];

		// FIXME: Setting the object as the value of this node makes it appear
		// in the unknownAttributes dictionary of the message. The object will
		// still be a distant object so perhaps this isn't the smartest thing to
		// do. If we were piping all messages directly into some common message
		// store (and thus re-serializing them), this would probably not matter
		// much.
		[value autorelease];
		value = [theObject retain];

		// The store ceases it's parsing duties after the closing </coreobject>
		// tag. So we dispose of the distant objects.
		[deserializer release];
		[proxy release];
		deserializer = nil;
		proxy = nil;
	}
	[super endElement: (NSString*)_name];
}
- (void)addversion: (NSString*)aVersion
{
	version = (NSUInteger)[aVersion longLongValue];
}

- (void)addbranch: (NSString*)aBranch
{
	[branch autorelease];
	branch = [aBranch retain];
}

- (void)addbackendName: (NSString*)aBackendName
{
	[backendName autorelease];
	backendName = [aBackendName retain];
}
- (void)addserialdata: (NSString*)aString
{
	NSData *someData = [aString base64DecodedData];
	if (nil == buffer)
	{
		buffer = [[NSMutableData alloc] initWithData: someData];
	}
	else
	{
		[buffer appendData: someData];
	}
}

- (ETXMLParser*)xmlParser
{
	return parser;
}

- (BOOL)xmlParserWillRead
{
	return YES;
}

- (ETXMLWriter*)xmlWriter
{
	return writer;
}

- (BOOL)xmlWriterWillStore
{
	return YES;
}


DEALLOC(
[backendName release];
[proxy release];
[writer release];
[branch release];
[uuid release];
[conversation release];
)
@end

@implementation XMPPObjectStoreVersionTag
- (void)startElement: (NSString*)_name
          attributes: (NSDictionary*)_attributes
{
	if (![_name isEqualToString: @"version"])
	{
		ETXMLNullHandler *handler = [[ETXMLNullHandler alloc] initWithXMLParser: parser parent: self key: _name];
		[handler startElement: _name attributes: _attributes];
		return;
	}
	depth++;
}

- (void)characters: (NSString*)cData
{
	if (self == value)
	{
		[value release];
		value = [[NSMutableString alloc] initWithString: cData];
	}
	else
	{
		[(NSMutableString*)value appendString: cData];
	}
}
@end

@implementation XMPPObjectStoreBranchTag
- (void)startElement: (NSString*)_name
          attributes: (NSDictionary*)_attributes
{
	if (![_name isEqualToString: @"branch"])
	{
		ETXMLNullHandler *handler = [[ETXMLNullHandler alloc] initWithXMLParser: parser parent: self key: _name];
		[handler startElement: _name attributes: _attributes];
		return;
	}
	depth++;
}

- (void)characters: (NSString*)cData
{
	if (self == value)
	{
		[value release];
		value = [[NSMutableString alloc] initWithString: cData];
	}
	else
	{
		[(NSMutableString*)value appendString: cData];
	}
}
@end

@implementation XMPPObjectStoreSerialDataTag
- (void)startElement: (NSString*)_name
          attributes: (NSDictionary*)_attributes
{
	if (![_name isEqualToString: @"serialdata"])
	{
		ETXMLNullHandler *handler = [[ETXMLNullHandler alloc] initWithXMLParser: parser parent: self key: _name];
		[handler startElement: _name attributes: _attributes];
		return;
	}
	if ([parent respondsToSelector:@selector(addChild:forKey:)])
	{
		[(id)parent addChild: [_attributes objectForKey: @"backend"] 
		              forKey: @"backendName"];
	}
	depth++;
}

- (void)characters: (NSString*)cData
{
	if (self == value)
	{
		[value release];
		value = [[NSMutableString alloc] initWithString: cData];
	}
	else
	{
		[(NSMutableString*)value appendString: cData];
	}
}
@end

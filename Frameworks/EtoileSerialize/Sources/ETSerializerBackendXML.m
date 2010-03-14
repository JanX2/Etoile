#include <objc/objc-api.h>
#import <EtoileFoundation/ETUUID.h>
#import <EtoileFoundation/NSData+Hash.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileXML/ETXMLWriter.h>
#import "ETSerializerBackendXML.h"
#import "ETDeserializerBackendXML.h"
#import "ETDeserializerBackend.h"
#import "ETDeserializer.h"
#import "ETObjectStore.h"
#import "IntMap.h"

@interface ETSerialObjectSocket (ETSerialObjectXMLWriting)
/**
 * Returns an XML writer attached directly to the socket.
 */
- (ETXMLWriter *) xmlWriter;

/**
 * Returns whether the XML writer will store the XML itself so that the
 * -writeBytes:count: method of the store does not need to be called.
 */
- (BOOL) xmlWriterWillStore;
@end

@implementation ETSerialObjectSocket (ETSerialObjectXMLWriting)
- (ETXMLWriter *) xmlWriter
{
	ETXMLSocketWriter *aWriter = [[[ETXMLSocketWriter alloc] init] autorelease];
	[aWriter setSocket: socket];
	return aWriter;
}

- (BOOL) xmlWriterWillStore
{
	return YES;
}
@end

/**
 * This backend can write both to local files and to (possibly remote) sockets.
 * Apparently it is most useful when the store provides a ETXMLWriter that does
 * stream the serialized data right away. Otherwise the XML tree is built by the
 * writer and written to the store when -flush is called.
 */
@implementation ETSerializerBackendXML
+ (id) serializerBackendWithStore:(id<ETSerialObjectStore>)aStore
{
	return [[[ETSerializerBackendXML alloc] initWithStore:aStore] autorelease];
}

+ (Class) deserializer
{
	return [ETDeserializerBackendXML class];
}

- (id) deserializer
{
	id deserializer = [[[[self class] deserializer] alloc] init];
	if([deserializer deserializeFromStore:store])
	{
		return [deserializer autorelease];
	}
	else
	{
		[deserializer release];
		return nil;
	}
	return nil;
}

- (void) setShouldIndent: (BOOL)aFlag
{
	[writer setAutoindent: aFlag];
}

- (void) startVersion:(int)aVersion
{
	[writer startElement: @"objects"
	          attributes: D(@"http://etoile-project.org/EtoileSerialize", @"xmlns",
			                @"1", @"version")];
}

- (id) initWithStore:(id<ETSerialObjectStore>)aStore
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	ASSIGN(store, aStore);

	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

	//If the store has it's own XML writer, we will reuse it.
	if ([store respondsToSelector:@selector(xmlWriter)])
	{
		ASSIGN(writer,[(ETSerialObjectSocket*)store xmlWriter]);
		xmlWriterWillStore = [(ETSerialObjectSocket*)store xmlWriterWillStore];
	}
	else
	{
		writer = [[ETXMLWriter alloc] init];
		[self setShouldIndent: YES];
	}
	return self;
}

- (void) dealloc
{
	NSFreeMapTable(refCounts);
	[writer release];
	[super dealloc];
}

- (void) flush
{
	NSMapEnumerator enumerator = NSEnumerateMapTable(refCounts);
	uintptr_t ref;
	uintptr_t refCount;
	while(NSNextMapEnumeratorPair(&enumerator, (void*)&ref, (void*)&refCount))
	{
		[writer startAndEndElement: @"refcount"
		        attributes: D([NSString stringWithFormat: @"%u", (CORef)ref], @"object")
		             cdata: [NSString stringWithFormat: @"%u", (unsigned int)refCount]];
	}
	NSEndMapTableEnumeration(&enumerator);
	[writer endElement: @"objects"];
	if (!xmlWriterWillStore)
	{
		NSString *graph = [writer endDocument];
		[store writeBytes: (unsigned char*)[graph UTF8String] count: [graph length]];
		[writer reset];
	}
	[store commit];
}

- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	[writer startElement: @"struct"
	          attributes: D([NSString stringWithCString: aStructName
	                                           encoding: NSASCIIStringEncoding],
	                        @"type",
                             [NSString stringWithCString: aName
	                                            encoding: NSASCIIStringEncoding],
	                        @"name")];
}

- (void) endStruct
{
	[writer endElement: @"struct"];
}

- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	[writer startElement: @"object"
	          attributes: D([NSString stringWithCString: aClass->name
	                                           encoding: NSASCIIStringEncoding],
	                        @"class",
	                        [NSString stringWithCString: aName
	                                           encoding: NSASCIIStringEncoding],
	                        @"name",
	                        [NSString stringWithFormat: @"%u", aReference],
	                        @"ref")];
}

- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	[writer startAndEndElement: @"objref"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                              @"name")
	                     cdata: [NSString stringWithFormat: @"%u", aReference]];
}

- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	int refCount = (int)NSIntMapGet(refCounts, anObjectID);
	NSIntMapInsert(refCounts, anObjectID,  (++refCount));
}

- (void) endObject
{
	[writer endElement: @"object"];
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	[writer startElement: @"array"
	          attributes: D([NSString stringWithCString: aName
	                                           encoding: NSASCIIStringEncoding],
	                        @"name",
	                        [NSString stringWithFormat: @"%u", aLength],
	                        @"length")];
}

- (void) endArray
{
	[writer endElement: @"array"];
}

- (void) setClassVersion:(int)aVersion
{
	[writer startAndEndElement: @"classVersion"
	                     cdata: [NSString stringWithFormat: @"%d", aVersion]];
}

#define STORE_METHOD(typeName, type, typeChar, printfType)\
- (void) store##typeName:(type)a##typeName withName:(char*)aName\
{\
	[writer startAndEndElement: @"" typeChar ""\
	                attributes: D([NSString stringWithCString: aName\
	                                                 encoding: NSASCIIStringEncoding],\
	                              @"name")\
	                     cdata: [NSString stringWithFormat: @"%" printfType "", a##typeName]];\
}

STORE_METHOD(Char, char, "c", "hhd")
STORE_METHOD(UnsignedChar, unsigned char, "C","hhu")
STORE_METHOD(Short, short, "s", "hd")
STORE_METHOD(UnsignedShort, unsigned short, "S","hu")
STORE_METHOD(Int, int, "i", "d")
STORE_METHOD(UnsignedInt, unsigned int, "I","u")
STORE_METHOD(Long, long, "l", "ld")
STORE_METHOD(UnsignedLong, unsigned long, "L", "lu")
STORE_METHOD(LongLong, long long, "q", "lld")
STORE_METHOD(UnsignedLongLong, unsigned long long, "Q","llu")
STORE_METHOD(Double, double, "d", "f")
STORE_METHOD(Float, float, "f", "f")

- (void) storeClass:(Class)aClass withName:(char*)aName
{
	[writer startAndEndElement: @"class"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                               @"name")
	                    cdata: NSStringFromClass(aClass)];
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	[writer startAndEndElement: @"sel"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                               @"name")
	                     cdata: NSStringFromSelector(aSelector)];
}
- (void) storeCString:(const char*)aCString withName:(char*)aName
{
	[writer startAndEndElement: @"str"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                               @"name")
	                     cdata: [NSString stringWithCString: aCString
                                                   encoding: NSASCIIStringEncoding]];
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	NSString *b64  = [[NSData dataWithBytes: aBlob length: aSize] base64String];
	[writer startAndEndElement: @"data"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                               @"name",
	                               [NSString stringWithFormat: @"%u", (unsigned)aSize],
	                               @"size")
	                    cdata: b64];
}
- (void) storeUUID:(unsigned char *)aUUID withName:(char *)aName
{
	//FORMAT("<uuid name='%s'>
	ETUUID * uuidObj = [[ETUUID alloc] initWithUUID:aUUID];
	[writer startAndEndElement: @"uuid"
	                attributes: D([NSString stringWithCString: aName
	                                                 encoding: NSASCIIStringEncoding],
	                               @"name")
	                     cdata: [uuidObj stringValue]];
	[uuidObj release];
}
@end

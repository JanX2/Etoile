/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */

#import "ETXMLDeserializationHandler.h"
#import "ETDeserializerBackendXML.h"
#import "ETDeserializer.h"
#import "ETUtility.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileXML/ETXMLNullHandler.h>
#import <EtoileXML/ETXMLParser.h>
#import <EtoileXML/ETXMLParserDelegate.h>
#import "NSString+Conversions.h"

@implementation ETXMLDeserializationHandler
- (void) setDeserializer: (ETDeserializer*)aDeserializer
{
		[deserializer autorelease];
		deserializer = [aDeserializer retain];
}

- (void) setName: (NSString *)aName
{
	[name autorelease];
	name = [aName retain];
}
- (void) setBackendHasPrincipalRef: (BOOL) hasPrincipalRef
{
	backendHasPrincipalRef = hasPrincipalRef;

	// This causes the change to be broadcast down the tree if the principalRef
	// has been set:
	if ([parent respondsToSelector: @selector(setBackendHasPrincipalRef:)]
	  && hasPrincipalRef)
	{
		[(ETXMLDeserializationHandler*)parent setBackendHasPrincipalRef: hasPrincipalRef];
	}
}
- (void) startElement: (NSString *)nodeName
           attributes: (NSDictionary *)someAttributes
{
	// Create string representing the class that shall be used for an element of
	// type nodeName.
	NSString *classString = [NSString stringWithFormat: @"ETXML%@DeserializationHandler", nodeName];

	if ([classString isEqual: NSStringFromClass([self class])])
	{
		// In this case, the class is setup for the current element and we don't
		// want to start a new one.
		return;
	}
	Class nodeClass = NSClassFromString(classString);
	if (Nil == nodeClass)
	{
		// Ignore all unsupported elements.
		nodeClass = [ETXMLNullHandler class];
	}

	id nextHandler = [[[nodeClass alloc] initWithXMLParser: parser
	                                               parent: self
	                                                  key: nodeName] autorelease];
	if ([nodeClass isSubclassOfClass: [ETXMLDeserializationHandler class]])
	{
		[nextHandler setDeserializer: deserializer];
		[nextHandler setBackendHasPrincipalRef: backendHasPrincipalRef];
		[(ETXMLDeserializationHandler*)nextHandler setName: [someAttributes objectForKey: @"name"]];
	}

	[nextHandler startElement: nodeName attributes: someAttributes];
}

- (void) endElement: (NSString *)nodeName
{
	[parser setContentHandler: parent];
}

- (id) rootAncestor
{
	if ([parent respondsToSelector: @selector(rootAncestor)])
	{
		return [(ETXMLDeserializationHandler*)parent rootAncestor];
	}
	else
	{
		return parent;
	}
}

- (char*) name
{
	return (char*)[name cStringUsingEncoding: NSASCIIStringEncoding];
}

DEALLOC([deserializer release];
        [name release];)
@end

@implementation ETXMLobjectsDeserializationHandler

- (void) startElement: (NSString *)nodeName
           attributes: (NSDictionary *)someAttributes
{
	if ([nodeName isEqual: @"objects"])
	{
		if (![[someAttributes objectForKey: @"xmlns"] isEqual: @"http://etoile-project.org/EtoileSerialize"]
		  || (1 != [[someAttributes objectForKey: @"version"] integerValue]))
		{
			// Either <objects> is in the wrong namespace or it indicates a
			// wrong version (or both). Thus the rest of the tree is ignored.
			ETXMLNullHandler *nullHandler = [[[ETXMLNullHandler alloc] initWithXMLParser: parser
			                                   parent: self key: name] autorelease];
			[nullHandler startElement: nodeName attributes: someAttributes];
		}
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

@end

@interface ETXMLobjectDeserializationHandler : ETXMLDeserializationHandler
@end

@implementation ETXMLobjectDeserializationHandler
- (void) startElement: (NSString *) nodeName
           attributes: (NSDictionary *)someAttributes
{
	if ([nodeName isEqual: @"object"])
	{
		CORef objRef = (CORef)[[someAttributes objectForKey: @"ref"] intValue];
		NSString *className = [someAttributes objectForKey: @"class"];
		[deserializer beginObjectWithID: objRef
		                      withClass: NSClassFromString(className)];
		if (NO == backendHasPrincipalRef)
		{
			[(ETDeserializerBackendXML*)[self rootAncestor] setPrincipalObjectRef: objRef];
			[(ETDeserializerBackendXML*)[self rootAncestor] setPrincipalObjectClass: className];
			[self setBackendHasPrincipalRef: YES];
		}
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

- (void) endElement: (NSString *) nodeName
{
	if ([nodeName isEqual: @"object"])
	{
		[deserializer endObject];
	}
	[super endElement: nodeName];
}
@end

@interface ETXMLstructDeserializationHandler : ETXMLDeserializationHandler
@end

@implementation ETXMLstructDeserializationHandler
- (void) startElement: (NSString *)nodeName
           attributes: (NSDictionary *)someAttributes
{
	if([nodeName isEqual: @"struct"])
	{
		char *type = (char*)[[someAttributes objectForKey: @"type"] cStringUsingEncoding: NSASCIIStringEncoding];
		[deserializer beginStruct: type  withName: [self name]];
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

- (void) endElement: (NSString *)nodeName
{
	if([nodeName isEqual: @"struct"])
	{
		[deserializer endStruct];
	}
	[super endElement: nodeName];
}
@end

@interface ETXMLarrayDeserializationHandler : ETXMLDeserializationHandler
@end

@implementation ETXMLarrayDeserializationHandler
- (void) startElement: (NSString *)nodeName
           attributes: (NSDictionary *)someAttributes
{
	if ([nodeName isEqual: @"array"])
	{
		unsigned int len = [[someAttributes objectForKey: @"length"] unsignedIntValue];
		[deserializer beginArrayNamed: [self name]
		                   withLength: len];
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

- (void) endElement: (NSString *)nodeName
{
	if ([nodeName isEqual: @"array"])
	{
		[deserializer endArray];
	}
	[super endElement: nodeName];
}
@end

@interface ETXMLclassVersionDeserializationHandler : ETXMLDeserializationHandler
@end

@implementation ETXMLclassVersionDeserializationHandler
- (void) characters: (NSString *)chars
{
	[deserializer setClassVersion: [chars intValue]];
}
@end

// Macro do ease the generation of handler classes that deserialize just by
// loading their cdata as a numeric value.
#define CLASS_LOADING(nodeType,typeName,type,stringConversionType) @interface ETXML##nodeType##DeserializationHandler : ETXMLDeserializationHandler \
@end \
\
@implementation ETXML##nodeType##DeserializationHandler \
- (void) characters: (NSString *)chars \
{\
	[deserializer load##typeName: (type)[chars stringConversionType##Value] withName: [self name]]; \
}\
@end

// Simple ivar-loading nodes, using the macro defined above.
CLASS_LOADING(c,Char,char,char)
CLASS_LOADING(C,UnsignedChar,unsigned char,unsignedChar)
CLASS_LOADING(objref,ObjectReference,CORef,int)
CLASS_LOADING(s,Short,short,short)
CLASS_LOADING(S,UnsignedShort,unsigned short,unsignedShort)
CLASS_LOADING(i,Int,int,int)
CLASS_LOADING(I,UnsignedInt,unsigned int,unsignedInt)
CLASS_LOADING(l,Long,long,long)
CLASS_LOADING(L,UnsignedLong,unsigned long,unsignedLong)
CLASS_LOADING(q,LongLong,long long,longLong)
CLASS_LOADING(Q,UnsignedLongLong,unsigned long long,unsignedLongLong)

CLASS_LOADING(d,Double,double,double)
CLASS_LOADING(f,Float,float,float)


@interface ETXMLclassDeserializationHandler: ETXMLDeserializationHandler
@end

@implementation ETXMLclassDeserializationHandler
- (void) characters: (NSString *)chars
{
	[deserializer loadClass: NSClassFromString(chars)
	               withName: [self name]];
}
@end

@interface ETXMLselectorDeserializationHandler: ETXMLDeserializationHandler
@end

@implementation ETXMLselectorDeserializationHandler
- (void) characters: (NSString *)chars
{
	[deserializer loadSelector: NSSelectorFromString(chars)
	                  withName: [self name]];
}
@end

@interface ETXMLstrDeserializationHandler: ETXMLDeserializationHandler
@end

@implementation ETXMLstrDeserializationHandler
- (void) characters: (NSString *)chars
{
	[deserializer loadCString: (char*)[chars cStringUsingEncoding: NSASCIIStringEncoding]
	                 withName: [self name]];
}
@end

@interface ETXMLdataDeserializationHandler : ETXMLDeserializationHandler
{
	NSUInteger size;
}
@end

@implementation ETXMLdataDeserializationHandler
- (void) startElement: (NSString*) nodeName
           attributes: (NSDictionary*) someAttributes
{
	if ([nodeName isEqual: @"data"])
	{
		size = [[someAttributes objectForKey: @"size"] unsignedIntValue];
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

- (void) characters: (NSString*)chars
{

	NSData *theData = [chars base64DecodedData];
	NSUInteger length = [theData length];
	if (size != length)
	{
		NSDebugLog(@"Size inconsistency in data element named '%@' detected", name);
	}
	[deserializer loadData: (void*)[theData bytes]
	                ofSize: MIN(size,length)
	              withName: [self name]];
}
@end

@interface ETXMLuuidDeserializationHandler : ETXMLDeserializationHandler
@end

@implementation ETXMLuuidDeserializationHandler
- (void) characters: (NSString *)chars
{
	[deserializer loadUUID: (unsigned char *)[chars cStringUsingEncoding: NSASCIIStringEncoding]
	              withName: [self name]];
}
@end

@interface ETXMLrefcountDeserializationHandler: ETXMLDeserializationHandler
{
	CORef reference;
}
@end

@implementation ETXMLrefcountDeserializationHandler
- (void) startElement: (NSString *)nodeName
           attributes: (NSDictionary *)someAttributes
{
	if ([nodeName isEqual: @"refcount"])
	{
		reference = (CORef)[[someAttributes objectForKey: @"object"] intValue];
	}
	else
	{
		[super startElement: nodeName attributes: someAttributes];
	}
}

- (void) characters: (NSString *)chars
{
	[deserializer setReferenceCountForObject: reference
	                                      to: [chars unsignedIntValue]];
}
@end

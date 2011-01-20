/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocHTMLElement.h"

@interface DocHTMLElement (Private)
- (void) collectChildContentWithString: (NSMutableString *)buf;
@end

@interface BlankHTMLElement : DocHTMLElement 
@end

@implementation BlankHTMLElement

- (NSString *) content
{
	NSMutableString *buf = AUTORELEASE([NSMutableString new]);
	[self collectChildContentWithString: buf];
	return buf;
}

@end


@implementation DocHTMLElement

+ (DocHTMLElement *) blankElement
{
	return AUTORELEASE([[BlankHTMLElement alloc] initWithName: @"Blank"]);
}

+ (DocHTMLElement *) elementWithName: (NSString *) aName
{
	return AUTORELEASE([[DocHTMLElement alloc] initWithName: aName]);
}

- (DocHTMLElement *) initWithName: (NSString *) aName
{
	SUPERINIT;
	children = [NSMutableArray new];
	attributes = [NSMutableDictionary new];
	elementName = [[NSString alloc] initWithString: aName];
	blockElementNames = [[NSSet alloc] initWithObjects: @"div", @"dt", @"dl", nil];
	return self;
}

- (void) dealloc
{
	[children release];
	[attributes release];
	[elementName release];
	[blockElementNames release];
	[super dealloc];
}

- (BOOL) isEqual: (id)anObject
{
	return [[self description] isEqualToString: [anObject description]];
}

- (DocHTMLElement *) addText: (NSString *) aText
{
	if (aText)
	{
		[children addObject: aText];
	}
	return self;
}

- (DocHTMLElement *) add: (DocHTMLElement *) anElem 
{
	if (anElem)
	{
		[children addObject: anElem];
	}
	return self;
}

- (DocHTMLElement *) id: (NSString *) anID
{
	if (anID)
	{
		[attributes setObject: anID forKey: @"id"];
	}
	return self;
}

- (DocHTMLElement *) class: (NSString *) aClass
{
	if (aClass)
	{
		[attributes setObject: aClass forKey: @"class"];
	}
	return self;
}

- (DocHTMLElement *) name: (NSString *) aName
{
	if (aName)
	{
		[attributes setObject: aName forKey: @"name"];
	}
	return self;
}

/*
 forwarding...
 */

- (NSMethodSignature*) methodSignatureForSelector: (SEL)aSelector
{
	NSString *sig = NSStringFromSelector(aSelector);
	//NSLog (@"methodSignature for selector <%@>", sig);
	NSArray *components = [sig componentsSeparatedByString: @":"];
	NSMutableString *signature = [NSMutableString stringWithString: @"@@:"];
	NSUInteger nbOfComponents = [components count];

	for (int i=0; i < nbOfComponents; i++)
	{
		NSString *component = [components objectAtIndex: i];

		if ([component length] == 0)
			continue;

		//NSLog (@"component <%@>", component);
		[signature appendString: @"@"];
	}
	//  NSLog (@"generated sig <%@> for sel<%@>", signature, sig);
	return [NSMethodSignature signatureWithObjCTypes: [signature UTF8String]];
}

#define CALLM(assig,asig)\
	if ([component isEqualToString: assig])\
	{\
		id arg;\
		[invocation getArgument: &arg atIndex: i + 2];\
		[self asig: arg];\
	}

- (void) forwardInvocation: (NSInvocation *) invocation
{
	//NSLog (@"invocation called <%@>", NSStringFromSelector([invocation selector]));
	NSString *sig = NSStringFromSelector([invocation selector]);
	NSArray *components = [sig componentsSeparatedByString: @":"];
	NSUInteger nbOfComponents = [components count];

	for (int i = 0; i < nbOfComponents; i++)
	{
		NSString *component = [components objectAtIndex: i];

		if ([component length] == 0)
			continue;

		//NSLog (@"component <%@>", component);
		CALLM(@"id",id);
		CALLM(@"class",class);
		CALLM(@"with",with);
		CALLM(@"and",and);
	}

	//NSLog (@"after invocation of <%@>:\n%@", sig, [self content]);
	[invocation setReturnValue: &self];
}

- (DocHTMLElement *) with: (id) something
{
	if ([something isKindOfClass: [NSString class]])
	{
	return [self addText: something];
	} 
	else
	{
	return [self add: something];
	}
}

- (DocHTMLElement *) and: (id) something
{
	return [self with: something];
}

- (void) collectChildContentWithString: (NSMutableString *)buf
{
	for (id elem in children)
	{
		if ([elem isKindOfClass: [DocHTMLElement class]])
		{
			[buf appendString: [elem content]];
		}
		else if ([elem isKindOfClass: [NSString class]]) 
		{
			[buf appendString: elem];
		}
		else 
		{
			[buf appendString: [elem description]];
		}
	}
}

- (NSString *) content
{
	NSMutableString* buf = AUTORELEASE([NSMutableString new]);
	BOOL insertNewLine = [blockElementNames containsObject: elementName];

	[buf appendFormat: @"<%@", elementName];
	for (NSString *key in attributes)
	{
		[buf appendFormat: @" %@=\"%@\"", key, [attributes objectForKey: key]];
	}
	[buf appendString: @">"];
	if (insertNewLine)
		[buf appendString: @"\n"];
	
	[self collectChildContentWithString: buf];

	[buf appendFormat: @"</%@>", elementName];
	if (insertNewLine)
		[buf appendString: @"\n"];

	return buf;
}

- (NSString *) description
{
	return [self content];
}

@end

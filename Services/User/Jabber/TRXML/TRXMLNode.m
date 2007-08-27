//
//  TRXMLNode.m
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "TRXMLNode.h"
#import "../Macros.h"
#include <stdio.h>

static inline NSString* escapeXMLCData(NSString* _XMLString)
{
	NSMutableString * XMLString = [NSMutableString stringWithString:_XMLString];
	[XMLString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0,[XMLString length])];
	return XMLString;
}

static inline NSString* unescapeXMLCData(NSString* _XMLString)
{
	NSMutableString * XMLString = [NSMutableString stringWithString:_XMLString];
	[XMLString replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&apos;" withString:@"'" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:0 range:NSMakeRange(0,[XMLString length])];
	return XMLString;
}


//TODO: Generalise this as a filtered array enumerator
@interface TRXMLNodeChildEnumerator : NSEnumerator
{
	unsigned int index;
	NSArray * elements;
}
+ (TRXMLNodeChildEnumerator*) enumeratorWithElements:(NSArray*)anArray;
@end
@implementation TRXMLNodeChildEnumerator
- (TRXMLNodeChildEnumerator*) initWithElements:(NSArray*)anArray
{
	SUPERINIT;
	elements = [anArray retain];
	return self;
}
+ (TRXMLNodeChildEnumerator*) enumeratorWithElements:(NSArray*)anArray
{
	return [[TRXMLNodeChildEnumerator alloc] initWithElements:anArray];
}
- (NSArray *)allObjects
{
	NSMutableArray * elementsLeft = AUTORELEASED(NSMutableArray);
	TRXMLNode * nextObject;
	while((nextObject = [self nextObject]) != nil)
	{
		[elementsLeft addObject:nextObject];
	}
	return elementsLeft;
}
- (id)nextObject
{
	unsigned int count = [elements count];
	while(index < count)
	{
		id nextObject = [elements objectAtIndex:index++];
		if([nextObject isKindOfClass:[TRXMLNode class]])
		{
			return nextObject;
		}
	}
	return nil;
}
@end

@implementation TRXMLNode

- (id) init
{
	elements = [[NSMutableArray alloc] init];
	plainCDATA = [[NSMutableString alloc] init];
	childrenByName = [[NSMutableDictionary alloc] init];
	return [super init];
}

+ (id) TRXMLNodeWithType:(NSString*)type
{
	return [[[TRXMLNode alloc] initWithType:type]autorelease];
}

+ (id) TRXMLNodeWithType:(NSString*)type attributes:(NSDictionary*)_attributes
{
	return [[[TRXMLNode alloc] initWithType:type attributes:_attributes] autorelease];
}

- (id) initWithType:(NSString*)type
{
	return [self initWithType:type attributes:nil];
}

- (id) initWithType:(NSString*)type attributes:(NSDictionary*)_attributes
{
	nodeType = [type retain];
	attributes = [_attributes retain];
	return [self init];
}


//Default implementation.  Returns parse control to parent at end of node.
- (void)endElement:(NSString *)_Name
{
/*	NSLog(@"Ending Element %@", _Name);*/
	if([_Name isEqualToString:nodeType])
	{
		[parser setContentHandler:parent];
		[parent addChild:(id)self];
	}
}

- (void)startElement:(NSString *)_Name
		  attributes:(NSDictionary *)_attributes
{
/*	NSLog(@"Starting element %@ with attributes:", _Name);
	NSEnumerator * enumerator = [_attributes keyEnumerator];
	NSString * key = [enumerator nextObject];
	while(key != nil)
	{
		NSLog(@"%@=%@", key, [_attributes objectForKey:key]);
		key = [enumerator nextObject];
	}*/
	id newNode = [[TRXMLNode alloc] initWithType:_Name attributes:_attributes];
	[newNode setParser:parser];
	[newNode setParent:self];
	[parser setContentHandler:newNode];		
}


- (void)characters:(NSString *)_chars
{
	NSString * plainChars = unescapeXMLCData(_chars);
	id lastElement = [elements lastObject];
	//If the last element is a string
	if([lastElement isKindOfClass:[NSString class]])
	{
		NSString * combinedString = [lastElement stringByAppendingString:plainChars];
		[elements removeLastObject];
		[elements addObject:combinedString];
	}
	else
	{
		[elements addObject:plainChars];
	}
	[plainCDATA appendString:plainChars];
}

- (NSString*) type
{
	return nodeType;
}

- (NSString*) stringValueWithIndent:(int)indent
{
	//Open tag
	NSMutableString * XML = [NSMutableString stringWithFormat:@"<%@",nodeType];
	//Number of tabs to indent
	NSMutableString * indentString = @"";
	if(indent >= 0)
	{
		indentString = [NSMutableString stringWithString:@"\n"];
	}
	
	for(int i=0 ; i<indent ; i++)
	{
		[indentString appendString:@"\t"];
	}
	
	//Add attributes
	if(attributes != nil)
	{
		NSEnumerator *enumerator = [attributes keyEnumerator];		
		NSString* key;
		while ((key = (NSString*)[enumerator nextObject])) 
		{
			[XML appendString:[NSString stringWithFormat:@" %@=\"%@\"",key, (NSString*)[attributes objectForKey:key]]];
		}
	}
	
	//If we just have CDATA (no children)
	if([elements count] > 0 && [childrenByName count] == 0)
	{
		[XML appendString:@">"];
		[XML appendString:escapeXMLCData([NSMutableString stringWithString:plainCDATA])];
		[XML appendString:[NSString stringWithFormat:@"</%@>",nodeType]];
	}
	else if([elements count] > 0)
	{
		NSMutableString * childIndentString = [NSMutableString stringWithString:indentString];

		//Children are indented one more tab than parents
		if(indent > 0)
		{
			[childIndentString appendString:@"\t"];
		}
		//End the start element
		[XML appendString:@">"];
		
		Class stringClass = NSClassFromString(@"NSString");
		//Add children and CDATA
		FOREACHI(elements, element)
		{
			//Indent the child element
			[XML appendString:childIndentString];
			if([element isKindOfClass:stringClass])
			{
				[XML appendString:escapeXMLCData(element)];
			}
			else
			{
				if(indent < 0)
				{
					[XML appendString:[element stringValueWithIndent:indent]];					
				}
				else
				{
					[XML appendString:[element stringValueWithIndent:indent + 1]];
				}
			}
		}
		[XML appendString:indentString];
		[XML appendString:[NSString stringWithFormat:@"</%@>",nodeType]];
	}
	else
	{
		[XML appendString:@"/>"];
	}
	return XML;
}


- (NSString*) stringValue
{
	return [self stringValueWithIndent:0];
}
- (NSString*) unindentedStringValue
{
	return [self stringValueWithIndent:-1];
}

- (void) addChild:(id)anElement
{
	if(![anElement isKindOfClass:[TRXMLNode class]])
	{
		if([anElement respondsToSelector:@selector(xmlValue)])
		{
			//Indirect call to eliminate compiler warning that selector might not be found.
			anElement = [anElement performSelector:@selector(xmlValue)];
		}
		else
		{
			return;
		}
	}
	children++;
	id lastElement = [elements lastObject];
	//If there is nothing other than white space between this child and the last one, the XML specification instructs us to ignore the whitespace
	if([lastElement isKindOfClass:[NSString class]] && [[lastElement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
	{
		[elements removeLastObject];
	}
	[elements addObject:anElement];
	NSString * childType = [anElement type];
	NSMutableSet * childrenWithName = [childrenByName objectForKey:childType];
	if(childrenWithName == nil)
	{
		childrenWithName = [NSMutableSet set];
		[childrenByName setObject:childrenWithName forKey:childType];
	}
	[childrenWithName addObject:anElement];
}

- (void) addCData:(id)newCData
{
	if([newCData isKindOfClass:[NSString class]])
	{
		[self characters:newCData];
	}
	else if([newCData respondsToSelector:@selector(stringValue)])
	{
		[self characters:[newCData stringValue]];
	}
}
//TODO: Implement hash: and isEqual so that this set actually works...
- (NSArray*) elements
{
	return elements;
}

- (NSSet*) getChildrenWithName:(NSString*)_name
{
	return [childrenByName objectForKey:_name];
}

- (unsigned int) children
{
	return children;
}

- (NSEnumerator*) childEnumerator
{
	return [TRXMLNodeChildEnumerator enumeratorWithElements:elements];
}


- (void) setParser:(id) XMLParser
{
	//Don't retain, since we can't release.
	parser = XMLParser;
}

- (void) setParent:(id) newParent
{
	parent = newParent;
}

- (NSString*) get:(NSString*)attribute
{
	return (NSString*)[attributes objectForKey:attribute];
}

- (void) set:(NSString*)attribute to:(NSString*) value
{
	if(attributes == nil)
	{
		attributes = [[NSMutableDictionary alloc] init];
	}
	//If we were passed an immutable object as the constructor, we need to make it mutable
	if(![attributes isMemberOfClass:[NSMutableDictionary class]])
	{
		id oldAttributes = attributes;
		attributes = [[NSMutableDictionary dictionaryWithDictionary:attributes] retain];
		[oldAttributes release];
	}	
	[attributes setObject:value forKey:attribute];
}

- (NSString *) cdata
{
	return plainCDATA;
}

- (void) setCData:(NSString*)newCData
{
	[plainCDATA release];
	plainCDATA = [newCData retain];
	for(unsigned int i=0 ; i < [elements count] ; i++)
	{
		while(i < [elements count] && [[elements objectAtIndex:i] isKindOfClass:[NSString class]])
		{
			[elements removeObjectAtIndex:i];
		}
	}
	[elements addObject:newCData];
}

- (void) dealloc
{
	[elements removeAllObjects];
	[elements release];
	[attributes release];
	[plainCDATA release];
	[nodeType release];
	[childrenByName release];
	[super dealloc];
}
@end


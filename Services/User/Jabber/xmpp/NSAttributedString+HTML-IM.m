//
//  NSAttributedString+HTML-IM.m
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSAttributedString+HTML-IM.h"
#import "ETXMLNode.h"
#include "../Macros.h"

static NSMapTable * STYLE_HANDLERS = NULL;

typedef NSString*(*styleHandler)(id);

NSString * foregroundColor(NSColor * aColour)
{
	float r,g,b,a;
	[[aColour colorUsingColorSpaceName:NSCalibratedRGBColorSpace]
			 getRed:&r
			  green:&g
			   blue:&b
			  alpha:&a];
	return [NSString stringWithFormat:@"color: #%.2x%.2x%.2x;",
		(int) (r * 255),
		(int) (g * 255),
		(int) (b * 255)];
}
NSString * cssGenericFontFamily(NSFontSymbolicTraits traits)
{
	if(traits & NSFontMonoSpaceTrait)
	{
		return @"monospace";
	}
	switch(traits & NSFontFamilyClassMask)
	{
#define FONT_FAMILY(value, name) case value: return name; break;
		case NSFontOldStyleSerifsClass:
		case NSFontTransitionalSerifsClass:
		case NSFontModernSerifsClass:
		case NSFontClarendonSerifsClass:
		case NSFontSlabSerifsClass:
		case NSFontOrnamentalsClass:
		FONT_FAMILY(NSFontFreeformSerifsClass, @"serif")
		FONT_FAMILY(NSFontSansSerifClass, @"sans-serif")
		FONT_FAMILY(NSFontScriptsClass, @"cursive")
		FONT_FAMILY(NSFontSymbolicClass, @"fantasy")
#undef FONT_FAMILY
	}
	return nil;
}
NSString * fontAttributes(NSFont * aFont)
{
	NSFontSymbolicTraits traits = [[aFont fontDescriptor] symbolicTraits];
	NSString * genericFamily = cssGenericFontFamily(traits);
	NSMutableString * style;
	if(genericFamily == nil)
	{
		style = [NSMutableString stringWithFormat:@"font-family: %@;",
			[aFont familyName]];
	}
	else
	{
		style = [NSMutableString stringWithFormat:@"font-family: %@, %@;",
			[aFont familyName],
			genericFamily];
	}
	if(traits & NSFontItalicTrait)
	{
		[style appendString:@"font-style: oblique;"];
	}
	if(traits & NSFontBoldTrait)
	{
		[style appendString:@"font-weight: bold;"];
	}
	NSDictionary * attributes = [[aFont fontDescriptor] fontAttributes];
	NSString * attribute;
	if((attribute = [attributes objectForKey:NSFontSizeAttribute]))
	{
		[style appendFormat:@"font-size: %.1fpt;", [attribute floatValue]];
	}
	if((attribute = [attributes objectForKey:NSUnderlineStyleAttributeName]))
	{
		[style appendString:@"text-decoration: underline;"];
	}
	return style;
}


NSString * styleFromAttributes(NSDictionary * attributes)
{
	NSMutableString * style = [NSMutableString string];
	if(STYLE_HANDLERS == nil)
	{
		STYLE_HANDLERS = NSCreateMapTable(NSNonRetainedObjectMapKeyCallBacks,NSNonOwnedPointerMapValueCallBacks,10);
		NSMapInsert(STYLE_HANDLERS,NSForegroundColorAttributeName,(void*)foregroundColor);
		NSMapInsert(STYLE_HANDLERS,NSFontAttributeName,(void*)fontAttributes);
	}
	NSEnumerator * enumerator = [attributes keyEnumerator];
	id key;
	while(nil != (key = [enumerator nextObject]))
	{
		styleHandler handler = NSMapGet(STYLE_HANDLERS,key);
		if(handler != NULL)
		{
			[style appendString:handler([attributes objectForKey:key])];
		}
	}
	return style;
}

void addCdataWithLineBreaksToNode(ETXMLNode * node, NSString* cdata)
{
	ETXMLNode * br = [ETXMLNode ETXMLNodeWithType:@"br"];
	NSArray * segments = [cdata componentsSeparatedByString:@"\n"];
	if([segments count] > 1)
	{
		int i;
		for(i=0 ; i < [segments count] -1 ; i++)
		{
			[node addCData:[segments objectAtIndex:i]];
			[node addChild:br];
		}
		[node addCData:[segments objectAtIndex:i]];		
	}
	else
	{
		[node addCData:cdata];
	}
}

@implementation NSAttributedString (XHTML_IM)
- (ETXMLNode*) xhtmlimValue
{
	NSDictionary * htmlns = [NSDictionary dictionaryWithObject:@"http://jabber.org/protocol/xhtml-im"
														forKey:@"xmlns"];
	NSDictionary * bodyns = [NSDictionary dictionaryWithObject:@"http://www.w3.org/1999/xhtml"
														forKey:@"xmlns"];
	NSString * plainText = [self string];
	ETXMLNode * html = [ETXMLNode ETXMLNodeWithType:@"html" attributes:htmlns];
	ETXMLNode * body = [ETXMLNode ETXMLNodeWithType:@"body" attributes:bodyns];
	[html addChild:body];
	NSRange attributeRange;
	int start = 0;
	int end = [self length];
	while(start < end)
	{
		//Get the range and attributes:
		NSDictionary * attributes = [self attributesAtIndex:start effectiveRange:&attributeRange];
		NSString * css = styleFromAttributes(attributes);
		NSURL * linkTarget = [attributes objectForKey:NSLinkAttributeName];
		ETXMLNode * span;
		if(![css isEqualToString:@""] || linkTarget != nil)
		{
			if(linkTarget != nil)
			{
				span = [ETXMLNode ETXMLNodeWithType:@"a"];
				[span set:@"href" to:[NSString stringWithFormat:@"%@", linkTarget]];
			}
			else
			{
				span = [ETXMLNode ETXMLNodeWithType:@"span"];
			}
			if(![css isEqualToString:@""])
			{
				[span set:@"style" to:styleFromAttributes(attributes)];
			}
			addCdataWithLineBreaksToNode(span, [plainText substringWithRange:attributeRange]);
			[body addChild:span];
		}
		else
		{
			addCdataWithLineBreaksToNode(body, [plainText substringWithRange:attributeRange]);
		}
		start = attributeRange.location + attributeRange.length;
	}
	//NSLog(@"XHTML-IM: %@", [html stringValue]);
	return html;
}

- (NSString*) stringValueWithExpandedLinks
{
	NSMutableString * string = [NSMutableString stringWithString:[self string]];
	int length = [self length];
	int offset = 0;
	for(int i = 0 ; i<length ; i++)
	{
		NSRange range;
		NSString * href;
		if((href = [self attribute:NSLinkAttributeName
						   atIndex:i
					effectiveRange:&range]))
		{
			i += range.length;
			NSString * link = [NSString stringWithFormat:@" (%@)", href];
			[string insertString:link
						 atIndex:i + offset];
			offset += [link length];
		}
	}
	return string;
}
@end

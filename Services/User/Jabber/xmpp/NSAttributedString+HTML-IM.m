//
//  NSAttributedString+HTML-IM.m
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSAttributedString+HTML-IM.h"
#import "TRXMLNode.h"
#include "../Macros.h"

static NSMapTable * STYLE_HANDLERS = NULL;

typedef NSString*(*styleHandler)(id);

NSString * foregroundColor(NSColor * aColour)
{
	float r,g,b,a;
	[aColour getRed:&r
			  green:&g
			   blue:&b
			  alpha:&a];
	return [NSString stringWithFormat:@"color: #%.2x%.2x%.2x;",
		(int) (r * 255),
		(int) (g * 255),
		(int) (b * 255)];
}

NSString * fontAttributes(NSFont * aFont)
{
	NSDictionary * attributes = [[aFont fontDescriptor] fontAttributes];
	NSMutableString * style = [NSMutableString string];
	NSString * attribute;
	if((attribute = [attributes objectForKey:NSFontFamilyAttribute]))
	{
		[style appendFormat:@"font-family: %@;", attribute];
	}
	if((attribute = [attributes objectForKey:NSFontSizeAttribute]))
	{
		[style appendFormat:@"font-size: %.1fpt;", [attribute floatValue]];
	}
	if((attribute = [attributes objectForKey:NSUnderlineStyleAttributeName]))
	{
		[style appendString:@"text-decoration: underline;"];
	}
	NSFontSymbolicTraits traits = [[aFont fontDescriptor] symbolicTraits];
	if(traits & NSFontItalicTrait)
	{
		[style appendString:@"font-style: oblique;"];
	}
	if(traits & NSFontItalicTrait)
	{
		[style appendString:@"font-weight: bold;"];
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

@implementation NSAttributedString (XHTML_IM)
- (TRXMLNode*) xhtmlimValue
{
	NSDictionary * htmlns = [NSDictionary dictionaryWithObject:@"http://jabber.org/protocol/xhtml-im"
														forKey:@"xmlns"];
	NSDictionary * bodyns = [NSDictionary dictionaryWithObject:@"http://www.w3.org/1999/xhtml"
														forKey:@"xmlns"];
	NSString * plainText = [self string];
	TRXMLNode * html = [TRXMLNode TRXMLNodeWithType:@"html" attributes:htmlns];
	TRXMLNode * body = [TRXMLNode TRXMLNodeWithType:@"body" attributes:bodyns];
	[html addChild:body];
	NSRange attributeRange;
	int start = 0;
	int end = [self length];
	while(start < end)
	{
		//Get the range and attributes:
		NSDictionary * attributes = [self attributesAtIndex:start effectiveRange:&attributeRange];
		NSString * css = styleFromAttributes(attributes);
		TRXMLNode * span;
		if(![css isEqualToString:@""])
		{
			NSDictionary * style = [NSDictionary dictionaryWithObject:styleFromAttributes(attributes)
															   forKey:@"style"];
			span = [TRXMLNode TRXMLNodeWithType:@"span"
									 attributes:style];			
			[span addCData:[plainText substringWithRange:attributeRange]];
			[body addChild:span];
		}
		else
		{
			[body addCData:[plainText substringWithRange:attributeRange]];
		}
		start = attributeRange.location + attributeRange.length;
	}
	NSLog(@"XHTML-IM: %@", [html stringValue]);
	return html;
}
@end

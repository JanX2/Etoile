//
//  TRXMLDeclaration.h
//  Jabber
//
//  Created by Yen-Ju Chen on Thu Jul 12 2007.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "TRXMLDeclaration.h"
#import "../Macros.h"

@implementation TRXMLDeclaration

+ (id) TRXMLDeclaration
{
	TRXMLDeclaration *decl = [[TRXMLDeclaration alloc] initWithType: @"" attributes: [NSDictionary dictionaryWithObjectsAndKeys: @"version", @"1.0", @"encoding", @"UTF-8", nil]];
	return [decl autorelease];
}

- (NSString*) stringValueWithFlags:(NSDictionary *)flags
{
	/* Because this is the first element, we don't really care about indent */

	NSMutableString * XML = [NSMutableString stringWithFormat:@"<?xml"];

	/* version */
	NSString *value = [attributes objectForKey: @"version"];
	if (value == nil)
		value = @"1.0";

	[XML appendString: [NSString stringWithFormat: @" version=\"%@\"", value]];

	/* encoding */
	value = [attributes objectForKey: @"encoding"];
	if (value == nil)
		value = @"UTF-8";

	[XML appendString: [NSString stringWithFormat: @" encoding=\"%@\"", value]];

	/* standalone*/
	value = [attributes objectForKey: @"standalone"];
	if ((value != nil) && ([value isEqualToString: @"yes"] || [value isEqualToString: @"no"]))
	{
		[XML appendString: [NSString stringWithFormat: @" standalone=%@", value]];
	}

	/* We close it */
	[XML appendString: @"?>\n"];


	if([elements count] > 0)
	{
		//Add children (not CDATA)
		FOREACHI(elements, element)
		{
			if([element isKindOfClass: [TRXMLNode class]])
			{
				[XML appendString:[element stringValueWithFlags:flags]];
			}
		}
	}
	return XML;
}

- (void) addCData:(id)newCData
{
	/* We do nothing here */
}

- (void) setParent:(id) newParent
{
	/* We cannot have parent */
}

- (void) setCData:(NSString*)newCData
{
	/* We do nothing here */
}

- (void) dealloc
{
	[super dealloc];
}
@end


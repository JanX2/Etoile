//
//  NSTextView+ClickableLinks.m
//  Jabber
//
//  Created by David Chisnall on 24/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSTextView+ClickableLinks.h"


@implementation NSTextView (ClickableLinks)
- (void)makeLinksClickable
{
	NSTextStorage* textStorage = [self textStorage];
	NSString* string = [textStorage string];
	unsigned int length = [string length];
	NSRange searchRange = NSMakeRange(0, length);
	NSRange foundRange;
	NSCharacterSet * whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	[textStorage beginEditing];
	do 
	{
		/* Find the protocol://path separator. */
		foundRange=[string rangeOfString:@"://" options:0 range:searchRange];
		
		/* If there was a URL */
		if (foundRange.length > 0) 
		{
			NSRange startOfURLRange, endOfURLRange;
			/* Search backwards to find the start of the URL */
			searchRange.location = 0;
			searchRange.length = foundRange.location;
			startOfURLRange = [string rangeOfCharacterFromSet:whitespace
													  options:NSBackwardsSearch
														range:searchRange];
			if(startOfURLRange.length == 0)
			{
				startOfURLRange.location = 0;
			}
			else
			{
				startOfURLRange.location++;
			}
			/* Assume the URL ends with whitespace */
			searchRange.location = foundRange.location + 3;
			searchRange.length = length - searchRange.location;
			
			endOfURLRange = [string rangeOfCharacterFromSet:whitespace
													options:0 
													  range:searchRange];
			if (endOfURLRange.length == 0)
			{
				endOfURLRange.location = length;
			}
			
			/* Set foundRange to the URL range */
			foundRange.location = startOfURLRange.location;
			foundRange.length = endOfURLRange.location-foundRange.location;
			
			/* Range starting after the link */
			NSRange afterLink;
			afterLink.location = foundRange.location + foundRange.length;
			afterLink.length = 0;
			
			/* Don't do anything for tiny things that look like links. */
			if(foundRange.length > 4)
			{
				/* Make a URL from the link text */
				NSURL * url = [NSURL URLWithString:[string substringWithRange:foundRange]];
				
				NSDictionary * linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys: 
					url, NSLinkAttributeName,
					[NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
					[NSCursor pointingHandCursor],NSCursorAttributeName,
					[NSColor blueColor], NSForegroundColorAttributeName,
					nil];
				
				/* Clickify the link */
				[textStorage addAttributes:linkAttributes range:foundRange];
				
				/* Reset attributes for after the link */
				[textStorage removeAttribute:NSLinkAttributeName range:afterLink];
				[textStorage removeAttribute:NSCursorAttributeName range:afterLink];
				[textStorage removeAttribute:NSUnderlineStyleAttributeName range:afterLink];
				[textStorage removeAttribute:NSForegroundColorAttributeName range:afterLink];
			}
			
			/* Search after the end of the link */
			searchRange.location = afterLink.location;
			searchRange.length = length - searchRange.location;
		}
		
	} while (foundRange.length!=0); //repeat the do block until it no longer finds anything
	
	[textStorage endEditing];
}
@end

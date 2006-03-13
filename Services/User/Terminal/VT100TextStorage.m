/*
 **  VT100TextStorage.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Sathyam
 **
 **  Project: iTerm
 **
 **  Description: custom text storage object for vt100 terminal.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <iTerm/iTerm.h>
#import <iTerm/VT100TextStorage.h>

#define DEBUG_METHOD_TRACE		0
#define DEBUG_ALLOC		    	0

@implementation VT100TextStorage

- (id)initWithAttributedString:(NSAttributedString *)attrStr
{
#if DEBUG_ALLOC
    NSLog(@"VT100TextStorage: initWithAttributedString: %@", attrStr);
#endif
    if (self = [super init])
    {
	contents = attrStr ? [attrStr mutableCopy] : [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- init
{
    return [self initWithAttributedString:nil];
}

- (void)dealloc
{
#if DEBUG_ALLOC
    NSLog(@"VT100TextStorage: dealloc");
#endif    
    [contents release];
    [super dealloc];
}

- (NSString *)string
{
    return [contents string];
}

- (NSDictionary *)attributesAtIndex:(unsigned)location effectiveRange:(NSRange *)range
{
    return [contents attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{    
#if DEBUG_METHOD_TRACE
    NSLog(@"VT100TextStorage: replaceCharactersInRange: (%d,%d) withString:",
	  range.location, range.length);
    NSLog(@"old str = \n'%@'", [[contents attributedSubstringFromRange: range] string]);
    NSLog(@"new str = \n'%@'", str);
#endif

    // get the original length before edit
    int origLen = [self length];

#if 0
    // if the length did not change, check what really changed
    if(range.length == [str length])
    {
	NSString *origSubstring, *commonString;

	// strip out the common stuff
	origSubstring = [[contents attributedSubstringFromRange: range] string];
	commonString = [origSubstring commonPrefixWithString: str options: NSLiteralSearch];

	if([commonString length] > 0)
	{
	    NSString *origDiffString, *newDiffString;

	    if([commonString isEqualToString: origSubstring])
		origDiffString = @"";
	    else
		origDiffString = [origSubstring substringFromIndex: [commonString length]];

	    if([commonString isEqualToString: str])
		newDiffString = @"";
	    else
		newDiffString = [str substringFromIndex: [commonString length]];

	    //NSLog(@"Common string = \n'%@'", commonString);
	    //NSLog(@"origDiff string = \n'%@'", origDiffString);
	    //NSLog(@"newDiff string = \n'%@'", newDiffString);

	    // Now replace only the diff 
	    if([origDiffString length] > 0 && [newDiffString length] > 0)
	    {
		NSRange aRange;
		aRange = NSMakeRange(range.location + [commonString length], [origDiffString length]);
		[contents replaceCharactersInRange: aRange withString: newDiffString];
		[self edited:NSTextStorageEditedCharacters range:aRange changeInLength:[self length] - origLen];
		return;
	    }
	}
    }
#endif
    
    // else do the usual stuff.
    [contents replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:[self length] - origLen];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    // do a simple check on whether we are re-applying the same attributes
    NSDictionary *currentAttributes;
    NSRange longestEffectiveRange;

    currentAttributes = [contents attributesAtIndex: range.location longestEffectiveRange: &longestEffectiveRange inRange: range];
    if([currentAttributes isEqualToDictionary: attrs] && longestEffectiveRange.length == range.length)
	return;
    
    [contents setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (void) beginEditing
{
#if DEBUG_METHOD_TRACE
    //NSLog(@"VT100TextStorage: beginEditing");
#endif
    [super beginEditing];
}

- (void) endEditing
{
#if DEBUG_METHOD_TRACE
    //NSLog(@"VT100TextStorage: endEditing");
#endif
    [super endEditing];
}

@end 
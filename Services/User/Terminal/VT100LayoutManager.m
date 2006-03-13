/*
 **  VT100LayoutManager.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Sathyam
 **
 **  Project: iTerm
 **
 **  Description: Custom layout manager for VT100 terminal layout.
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

#import <iTerm/VT100LayoutManager.h>
#import <iTerm/VT100Typesetter.h>

#define DEBUG_METHOD_TRACE    	0
#define DEBUG_ALLOC		0

@implementation VT100LayoutManager

// we don't want to re-layout the text when the window size changes.
- (void)textContainerChangedGeometry:(NSTextContainer *)aTextContainer
{
#if DEBUG_METHOD_TRACE
    NSLog(@"VT100LayoutManager: textContainerChangedGeometry: ");
#endif
    // don't do anything.
}

- (void)textStorage:(NSTextStorage *)aTextStorage edited:(unsigned)mask range:(NSRange)range changeInLength:(int)lengthChange invalidatedRange:(NSRange)invalidatedCharRange
{
#if DEBUG_METHOD_TRACE
    NSLog(@"VT100LayoutManager: aTextStorage: edited: (0x%x) range: (%d,%d) changeInLength: (%d) invalidatedRange: (%d,%d)", mask, range.location, range.length, lengthChange, invalidatedCharRange.location, invalidatedCharRange.length);
#endif
    
#if 0
    // don't do anything if we just had attribute changes
    if(mask == NSTextStorageEditedAttributes)
    {
	//NSRange glyphRange;
	//glyphRange = [self glyphRangeForCharacterRange: range actualCharacterRange: nil];
	//[self invalidateDisplayForGlyphRange: glyphRange];
	return;
    }
    
    if (lengthChange == 0 && range.location == invalidatedCharRange.location && range.length == invalidatedCharRange.length)
    {
	// get the glyph range
	NSRange glyphRange;
	unsigned nextGlyph;
	int numLines = 0;

	//[self invalidateGlyphsForCharacterRange:invalidatedCharRange changeInLength:0 actualCharacterRange:nil];
	//glyphRange = [self glyphRangeForCharacterRange: range actualCharacterRange: nil];
	if(glyphRange.length > 0)
	{
	    // get the number of lines in the range
	    int i;
	    numLines = 1;

	    // invalidate the display for this glyph range
	    //[self invalidateDisplayForGlyphRange: glyphRange];

	    // call the typesetter to work on only this range
	    [[self typesetter] layoutGlyphsInLayoutManager: self startingAtGlyphIndex: glyphRange.location maxNumberOfLineFragments: numLines nextGlyphIndex: &nextGlyph];
	    NSRect glyphRect = [self boundingRectForGlyphRange:glyphRange inTextContainer:[[self firstTextView] textContainer]];
	    NSLogRect(glyphRect);
	    [[self firstTextView] setNeedsDisplayInRect: glyphRect];


	    return;
	}
    }
#endif

    [super textStorage: aTextStorage edited: mask range: range changeInLength: lengthChange invalidatedRange: invalidatedCharRange];
}

- (id) init
{
#if DEBUG_ALLOC
    NSLog(@"VT100LayoutManager: init");
#endif
    self = [super init];
    return self;
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"VT100LayoutManager: dealloc");
#endif
    [super dealloc];
}

@end

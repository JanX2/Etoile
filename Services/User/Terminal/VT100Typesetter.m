/*
 **  VT100Typesetter.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Sathyam
 **
 **  Project: iTerm
 **
 **  Description: Custom typesetter for VT100 terminal layout.
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
#import <iTerm/VT100Typesetter.h>
#import <iTerm/VT100Screen.h>

#define DEBUG_ALLOC	      0
#define DEBUG_METHOD_TRACE    0
#if DEBUG_METHOD_TRACE
static unsigned int invocationId = 0;
#endif

#define ISDOUBLEWIDTHCHARACTER(idx) ([[textStorage attribute:@"NSCharWidthAttributeName" atIndex:(idx) effectiveRange:nil] intValue]==2)
#define ISGRAPHICALCHARACTER(idx) ([[textStorage attribute:@"VT100GraphicalCharacter" atIndex:(idx) effectiveRange:nil] boolValue])

@implementation VT100Typesetter

// we should really be asking the NSTextContainer, butit may not exist yet, and there is no class method.
+ (float) lineFragmentPadding
{
    return (5);
}

- (id)init
{
#if DEBUG_ALLOC
    NSLog(@"%s(%d):-[VT100Typesetter init]", __FILE__, __LINE__);
#endif
    if((self = [super init]) == nil)
	return (nil);

    return (self);
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s(%d):-[VT100Typesetter dealloc]", __FILE__, __LINE__);
#endif
    [super dealloc];
}

- (float)baselineOffsetInLayoutManager:(NSLayoutManager *)layoutMgr glyphIndex:(unsigned)glyphIndex
{
    return (BASELINE_OFFSET);    
}

- (void)layoutGlyphsInLayoutManager:(NSLayoutManager *)layoutMgr startingAtGlyphIndex:(unsigned)startGlyphIndex maxNumberOfLineFragments:(unsigned)maxNumLines nextGlyphIndex:(unsigned *)nextGlyph
{
#if DEBUG_METHOD_TRACE
    unsigned int callId = invocationId++;
    
    NSLog(@"VT100Typesetter (%d): layoutGlyphsInLayoutManager: startGlyphIndex = %d; maxNumberOfLineFragments = %d",
	  callId, startGlyphIndex, maxNumLines);
#endif
    
    NSRect lineRect;
    unsigned int glyphIndex, charIndex, lineStartIndex, lineEndIndex;
    int numLines, j, length;
    BOOL atEnd, isValidIndex, lineEndCharExists;
    NSString *theString;
    NSRange characterRange, glyphRange;
    NSTextStorage *textStorage;
    NSRect previousRect;
	float defaultLineHeight;

    // grab the text container; we should have only one
    if(textContainer == nil)
    {
	textContainer = [[layoutMgr firstTextView] textContainer];
	lineFragmentPadding = [textContainer lineFragmentPadding];
    }

    // grab the textView; there should be only one
    if(textView == nil)
	textView = [layoutMgr firstTextView];

    textStorage = [layoutMgr textStorage];

    // grab the string; there should be only one
    theString = [textStorage string];
    //NSLog(@"theString = \n'%@'\n", theString);

    // grab the font; there should be only one
    if(font != [textView font])
    {
	font = [textView font];
	if(font != nil)
        // FIXME: -fontSize method doesn't seem to exist
	    //charWidth = [VT100Screen fontSize: font].width;
        charWidth = 8;
    }
	defaultLineHeight = [font defaultLineHeightForFont];

    length = [theString length];
    if(length <= 0)
    {
	*nextGlyph = 0;
	return;
    }

    // grab the origin of the screen
    originCharIndex = [screen getTVIndex: 0 y: 0];
    originGlyphIndex = [layoutMgr glyphRangeForCharacterRange: NSMakeRange(originCharIndex, 1) actualCharacterRange: nil].location;
    if(originGlyphIndex == 0)
	originLineFragmentRect = NSMakeRect(0, 0, [textContainer containerSize].width, [font defaultLineHeightForFont]);

    // process lines
    glyphIndex = startGlyphIndex;

    previousRect = NSZeroRect;
    for(numLines = 0; numLines < maxNumLines; numLines++)
    {
	atEnd = NO;
	lineEndCharExists = NO;

	// sanity check
	[layoutMgr glyphAtIndex: glyphIndex isValidIndex: &isValidIndex];
	if(isValidIndex == NO)
	    return;
	
	// get the corresponding character index
	charIndex = [layoutMgr characterIndexForGlyphAtIndex: glyphIndex];
	
	// go to the beginning of the line
	j = charIndex;
	while (j >= 0)
	{
	    if([theString characterAtIndex: j] == '\n')
		break;
	    j--;
	}
	lineStartIndex = j + 1;
	if(lineStartIndex  > charIndex)
	    lineStartIndex = charIndex;

	// go to the end of the line
	j = charIndex;
	while (j < length)
	{
	    
	    if([theString characterAtIndex: j] == '\n')
	    {
		lineEndCharExists = YES;
		break;
	    }
	    j++;
	}
	// Check if we reached the end of the text
	if(j == length)
	{
	    j--;
	    atEnd = YES;
	    lineEndCharExists = NO;
	}
	lineEndIndex = j;

	// build the line
	characterRange = NSMakeRange(lineStartIndex, lineEndIndex-lineStartIndex+1);
	glyphRange = [layoutMgr glyphRangeForCharacterRange: characterRange actualCharacterRange: nil];

	// calculate line width accounting for double width characters
	NSRange doubleWidthCharacterRange;
	id doubleWidthCharacterAttribute;
	float lineWidth = characterRange.length * charWidth;
	doubleWidthCharacterAttribute = [textStorage attribute:@"NSCharWidthAttributeName" atIndex:lineStartIndex longestEffectiveRange:&doubleWidthCharacterRange inRange:characterRange];
	if(doubleWidthCharacterAttribute != nil || doubleWidthCharacterRange.length != characterRange.length)
	{
	    lineWidth = 0;
	    for (j = lineStartIndex; j < lineEndIndex + 1; j++)
	    {
		lineWidth += ISDOUBLEWIDTHCHARACTER(j)?charWidth*2:charWidth;
	    }
	}

	// calculate the line fragment rectangle
	if(lineStartIndex == 0)
	    lineRect = NSMakeRect(0, 0, [textContainer containerSize].width, [font defaultLineHeightForFont]);
	else
	{
	    NSRect lastGlyphRect;
	    // check if we just processed the previous line, otherwise ask the layout manager.
	    if(previousRect.size.width > 0)
		lastGlyphRect = previousRect;
	    else
		lastGlyphRect = [layoutMgr lineFragmentRectForGlyphAtIndex: lineStartIndex-1 effectiveRange: nil];
	    // calculate next line based on previous line rectangle
	    lineRect = NSMakeRect(0, lastGlyphRect.origin.y + [font defaultLineHeightForFont], [textContainer containerSize].width, [font defaultLineHeightForFont]);
	}
#if DEBUG_METHOD_TRACE
	NSLog(@"(%d) Laying out line %f; numLines = %d", callId, lineRect.origin.y/[font defaultLineHeightForFont] + 1, numLines);
	NSLog(@"(%d) Line = '%@'", callId, [theString substringWithRange: characterRange]);
#endif
	// cache the rect for the next run, if any.
	previousRect = lineRect;
	
	// Now fill the line
	NSRect usedRect = lineRect;
	usedRect.size.width = lineWidth + 2*lineFragmentPadding;
	if(usedRect.size.width > lineRect.size.width)
	    usedRect.size.width = lineRect.size.width;
	[layoutMgr setTextContainer: textContainer forGlyphRange: glyphRange];
	[layoutMgr setLineFragmentRect: lineRect forGlyphRange: glyphRange usedRect: usedRect];
	[layoutMgr setLocation: NSMakePoint(lineFragmentPadding, [font defaultLineHeightForFont] - BASELINE_OFFSET) forStartOfGlyphRange: glyphRange];

	// If we encountered graphical characters, we need to specify the postion of the glyph since the current font may not have a native character, 
	// and the character may be of a different font and thus be of different width.
	NSRange graphicalCharacterRange;
	id graphicalCharacterAttribute;
	graphicalCharacterAttribute = [textStorage attribute:@"VT100GraphicalCharacter" atIndex:lineStartIndex longestEffectiveRange:&graphicalCharacterRange inRange:characterRange];
	if(graphicalCharacterAttribute != nil || graphicalCharacterRange.length != characterRange.length)
	{
	    NSRange singleGlyphRange, restOfLineGlyphRange;
	    float x = 0;
	    float theWidth;

	    for (j = lineStartIndex; j <= lineEndIndex; j++)
	    {
			theWidth = ISDOUBLEWIDTHCHARACTER(j)?charWidth*2:charWidth;
			
			graphicalCharacterAttribute = [textStorage attribute:@"VT100GraphicalCharacter" atIndex:j effectiveRange:nil];
			if(graphicalCharacterAttribute != nil)
			{
				singleGlyphRange = [layoutMgr glyphRangeForCharacterRange: NSMakeRange(j, 1) actualCharacterRange: nil];
				[layoutMgr setLocation: NSMakePoint(lineFragmentPadding+x, defaultLineHeight - BASELINE_OFFSET) forStartOfGlyphRange: singleGlyphRange];
				// adjust the rest of the line
				if(j < lineEndIndex)
				{
					restOfLineGlyphRange = [layoutMgr glyphRangeForCharacterRange: NSMakeRange(j+1, lineEndIndex-j+1) actualCharacterRange: nil];
					[layoutMgr setLocation: NSMakePoint(lineFragmentPadding+x+charWidth, defaultLineHeight - BASELINE_OFFSET) forStartOfGlyphRange: restOfLineGlyphRange];
				}
			}

			x+=theWidth;
	    }
	}
	
	// hide new line glyphs
	if(lineEndCharExists == YES)
	{
	    [layoutMgr setNotShownAttribute: YES forGlyphAtIndex: glyphRange.location + glyphRange.length - 1];
	}

	// cache the line rect for the screen origin if we processed it.
	if (originGlyphIndex >= glyphRange.location && originGlyphIndex < (glyphRange.location + glyphRange.length))
	    originLineFragmentRect = lineRect;
	

	// set the glyphIndex for the next run
	glyphIndex = glyphRange.location + glyphRange.length;

	// check if the last character on the last line is a new lince char; we have to add an extra line fragment.
	if((lineEndIndex > lineStartIndex) && (lineEndIndex == [theString length] - 1) &&
    ([theString characterAtIndex: lineEndIndex] == '\n'))
	{
	    lineRect.origin.y += [font defaultLineHeightForFont];
	    [layoutMgr setExtraLineFragmentRect:lineRect usedRect:lineRect textContainer: textContainer];
	}
	
	// if we are at the end of the text, pad any unused space and get out.
	[layoutMgr glyphAtIndex: glyphIndex isValidIndex: &isValidIndex];
	if(atEnd == YES || isValidIndex == NO)
	{

	    // if our content size has decreased, we should not be padding so that the layout manager
	    // can resize the textview.
	    if(length < previousLength)
		break;

	    // check how many lines of the screen we are filling. Pad any unused space.
	    if(originCharIndex < [theString length])
	    {
                usedScreenLines = floor((lineRect.origin.y + lineRect.size.height - originLineFragmentRect.origin.y)/[font defaultLineHeightForFont]);
		if(usedScreenLines < [screen height])
		{
		    lineRect.origin.y += [font defaultLineHeightForFont];
		    lineRect.size.height = ([screen height] - usedScreenLines) * [font defaultLineHeightForFont];
		    [layoutMgr setExtraLineFragmentRect:lineRect usedRect:lineRect textContainer: textContainer];
		}
	    }
	    
	    break;
	}
    }

    // cache the current for the next run
    previousLength = length;

    // set the next glyph to be laid out
    if(nextGlyph)
	*nextGlyph = glyphIndex;
}

- (VT100Screen *) screen
{
    return (screen);
}

- (void) setScreen: (VT100Screen *) aScreen
{
    screen = aScreen;
}

@end

// object version of NSRange
@implementation NSRangeObject

+ (id) rangeObjectWithRange: (NSRange) aRange
{
    id aRangeObject = [[NSRangeObject alloc] initWithRange: aRange];

    return ([aRangeObject autorelease]);
}

- (id) initWithRange: (NSRange) aRange
{
    if((self = [super init]) == nil)
	return (nil);

    [self setRange: aRange];

    return (self);
}

- (NSRange) range
{
    return (range);
}

- (void) setRange: (NSRange) aRange
{
    range = aRange;
}

- (int) location
{
    return (range.location);
}

- (int) length
{
    return (range.length);
}

@end

// object version of NSRect
@implementation NSRectObject

+ (id) rectObjectWithRect: (NSRect) aRect
{
    id aRectObject = [[NSRectObject alloc] initWithRect: aRect];

    return ([aRectObject autorelease]);
}

- (id) initWithRect: (NSRect) aRect
{
    if((self = [super init]) == nil)
	return (nil);

    [self setRect: aRect];

    return (self);
}

- (NSRect) rect
{
    return (rect);
}

- (void) setRect: (NSRect) aRect
{
    rect = aRect;
}

- (NSPoint) origin
{
    return (rect.origin);
}

- (NSSize) size
{
    return (rect.size);
}

@end

/*
 **  VT100Typesetter.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Sathyam
 **
 **  Project: iTerm
 **
 **  Description: Typesetter header file for custom layout.
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#ifndef GNUSTEP
#import <AppKit/NSTypesetter.h>
#else
#import <GNUstepGUI/GSTypesetter.h>
#define NSTypesetter GSTypesetter
#endif

#define BASELINE_OFFSET	3

@class VT100Screen;

@interface VT100Typesetter : NSTypesetter {

    // cached stuff
    NSFont *font;
    float charWidth;
    NSTextView *textView;
    NSTextContainer *textContainer;
    float lineFragmentPadding;
    unsigned int previousLength;
    VT100Screen *screen;
    int originCharIndex, originGlyphIndex, usedScreenLines;
    NSRect originLineFragmentRect;


    NSMutableArray *_glyphRanges, *_lineRects;
    int _numLines;

}

+ (float) lineFragmentPadding;

- (float)baselineOffsetInLayoutManager:(NSLayoutManager *)layoutMgr glyphIndex:(unsigned)glyphIndex;
- (void)layoutGlyphsInLayoutManager:(NSLayoutManager *)layoutMgr startingAtGlyphIndex:(unsigned)startGlyphIndex maxNumberOfLineFragments:(unsigned)maxNumLines nextGlyphIndex:(unsigned *)nextGlyph;

- (VT100Screen *) screen;
- (void) setScreen: (VT100Screen *) aScreen;

@end


// object version of NSRange
@interface NSRangeObject : NSObject
{
    NSRange range;
}

+ (id) rangeObjectWithRange: (NSRange) aRange;
- (id) initWithRange: (NSRange) aRange;

- (NSRange) range;
- (void) setRange: (NSRange) aRange;
- (int) location;
- (int) length;

@end

// object version of NSRect
@interface NSRectObject : NSObject
{
    NSRect rect;
}

+ (id) rectObjectWithRect: (NSRect) aRect;
- (id) initWithRect: (NSRect) aRect;

- (NSRect) rect;
- (void) setRect: (NSRect) aRect;
- (NSPoint) origin;
- (NSSize) size;

@end


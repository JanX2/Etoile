// -*- mode:objc -*-
// $Id: PTYTextView.m,v 1.250 2006/03/03 08:45:20 ujwal Exp $
/*
 **  PTYTextView.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: NSTextView subclass. The view object for the VT100 screen.
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

#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0
#define GREED_KEYDOWN         1

#import <iTerm/iTerm.h>
#import <iTerm/PTYTextView.h>
#import <iTerm/PTYSession.h>
#import <iTerm/VT100Screen.h>
#import <iTerm/FindPanelWindowController.h>
#import <iTerm/PreferencePanel.h>
#import <iTerm/PTYScrollView.h>
#import <iTerm/PTYTask.h>

#include <sys/time.h>

#define  SELECT_CODE 0x40
#define  CURSOR_CODE 0x80

#ifdef __APPLE__
static SInt32 systemVersion;
#endif

@implementation PTYTextView

+ (void) initialize
{
	// get system version number
	// get the system version since there is a useful call in 10.3 and up for getting a blod stroke
#ifdef __APPLE__   
	Gestalt(gestaltSystemVersion,&systemVersion); 
#endif   
}

- (id)initWithFrame: (NSRect) aRect
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    	
    self = [super initWithFrame: aRect];
    dataSource=_delegate=markedTextAttributes=NULL;
    
    [self setMarkedTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor yellowColor], NSBackgroundColorAttributeName,
            [NSColor blackColor], NSForegroundColorAttributeName,
            font, NSFontAttributeName,
            [NSNumber numberWithInt:2],NSUnderlineStyleAttributeName,
            NULL]];
	CURSOR=YES;
	lastFindX = startX = -1;
    markedText=nil;
    gettimeofday(&lastBlink, NULL);
	[[self window] useOptimizedDrawing:YES];
	    	
	// register for drag and drop
	[self registerForDraggedTypes: [NSArray arrayWithObjects:
        NSFilenamesPboardType,
        NSStringPboardType,
        nil]];
	
	// init the cache
	memset(charImages, 0, CACHESIZE*sizeof(CharCache));	
    charWidth = 12;
    oldCursorX = oldCursorY = -1;
    
    [self setUseTransparency: YES];
		
    return (self);
}

- (BOOL) resignFirstResponder
{
	
	//NSLog(@"0x%x: %s", self, __PRETTY_FUNCTION__);
	if(trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = 0;
		
	return (YES);
}

- (BOOL) becomeFirstResponder
{
	
	//NSLog(@"0x%x: %s", self, __PRETTY_FUNCTION__);
	// reset tracking rect
	if(trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:[self frame] owner: self userData: nil assumeInside: NO];
		
	return (YES);
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	int i;
    
	if(mouseDownEvent != nil)
    {
		[mouseDownEvent release];
		mouseDownEvent = nil;
    }
	
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
    for(i=0;i<16;i++) {
        [colorTable[i] release];
    }
    [defaultFGColor release];
    [defaultBGColor release];
    [defaultBoldColor release];
    [selectionColor release];
	[defaultCursorColor release];
	
    [font release];
	[nafont release];
    [markedTextAttributes release];
	[markedText release];
	
    [self resetCharCache];
    [super dealloc];
}

- (BOOL)shouldDrawInsertionPoint
{
#if 0 // DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView shouldDrawInsertionPoint]",
          __FILE__, __LINE__);
#endif
    return NO;
}

- (BOOL)isFlipped
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}


- (BOOL) antiAlias
{
    return (antiAlias);
}

- (void) setAntiAlias: (BOOL) antiAliasFlag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView setAntiAlias: %d]",
          __FILE__, __LINE__, antiAliasFlag);
#endif
    antiAlias = antiAliasFlag;
	forceUpdate = YES;
	[self resetCharCache];
	[self setNeedsDisplay: YES];
}

- (BOOL) disableBold
{
	return (disableBold);
}

- (void) setDisableBold: (BOOL) boldFlag
{
	disableBold = boldFlag;
	forceUpdate = YES;
	[self resetCharCache];
	[self setNeedsDisplay: YES];
}


- (BOOL) blinkingCursor
{
	return (blinkingCursor);
}

- (void) setBlinkingCursor: (BOOL) bFlag
{
	blinkingCursor = bFlag;
}


- (NSDictionary*) markedTextAttributes
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView selectedTextAttributes]",
          __FILE__, __LINE__);
#endif
    return markedTextAttributes;
}

- (void) setMarkedTextAttributes: (NSDictionary *) attr
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView setSelectedTextAttributes:%@]",
          __FILE__, __LINE__,attr);
#endif
    [markedTextAttributes release];
    [attr retain];
    markedTextAttributes=attr;
}

- (void) setFGColor:(NSColor*)color
{
    [defaultFGColor release];
    [color retain];
    defaultFGColor=color;
	[self resetCharCache];
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
	// reset our default character attributes    
}

- (void) setBGColor:(NSColor*)color
{
    [defaultBGColor release];
    [color retain];
    defaultBGColor=color;
	//    bg = [bg colorWithAlphaComponent: [[SESSION backgroundColor] alphaComponent]];
	//    fg = [fg colorWithAlphaComponent: [[SESSION foregroundColor] alphaComponent]];
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (void) setBoldColor: (NSColor*)color
{
    [defaultBoldColor release];
    [color retain];
    defaultBoldColor=color;
	[self resetCharCache];
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (void) setCursorColor: (NSColor*)color
{
    [defaultCursorColor release];
    [color retain];
    defaultCursorColor=color;
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (void) setSelectedTextColor: (NSColor *) aColor
{
	[selectedTextColor release];
	[aColor retain];
	selectedTextColor = aColor;
	[self _clearCacheForColor: SELECT_CODE];
	[self _clearCacheForColor: SELECT_CODE | BOLD_MASK];
	forceUpdate = YES;

	[self setNeedsDisplay: YES];
}

- (void) setCursorTextColor:(NSColor*) aColor
{
	[cursorTextColor release];
	[aColor retain];
	cursorTextColor = aColor;
	[self _clearCacheForColor: CURSOR_CODE];
	[self _clearCacheForColor: CURSOR_CODE | BOLD_MASK];
	
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (NSColor *) cursorTextColor
{
	return (cursorTextColor);
}

- (NSColor *) selectedTextColor
{
	return (selectedTextColor);
}

- (NSColor *) defaultFGColor
{
    return defaultFGColor;
}

- (NSColor *) defaultBGColor
{
	return defaultBGColor;
}

- (NSColor *) defaultBoldColor
{
    return defaultBoldColor;
}

- (NSColor *) defaultCursorColor
{
    return defaultCursorColor;
}

- (void) setColorTable:(int) index highLight:(BOOL)hili color:(NSColor *) c
{
	int idx=(hili?1:0)*8+index;
	
    [colorTable[idx] release];
    [c retain];
    colorTable[idx]=c;
	[self _clearCacheForColor: idx];
	[self _clearCacheForColor: (BOLD_MASK | idx)];
	
	[self setNeedsDisplay: YES];
}

- (NSColor *) colorForCode:(unsigned int) index 
{
    NSColor *color;
	
	if(index & SELECT_CODE)
		return (selectedTextColor);
	
	if(index & CURSOR_CODE)
		return (cursorTextColor);
	
	if (index&DEFAULT_FG_COLOR_CODE)
    {
		if (index&1) // background color?
		{
			color=defaultBGColor;
		}
		else if(index&BOLD_MASK)
		{
			color = [self defaultBoldColor];
		}
		else
		{
			color = defaultFGColor;
		}
    }
    else
    {
        color=colorTable[index&15];
    }
	
    return color;
    
}

- (NSColor *) selectionColor
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView selectionColor]",
          __FILE__, __LINE__);
#endif
    
    return selectionColor;
}

- (void) setSelectionColor: (NSColor *) aColor
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView setSelectionColor:%@]",
          __FILE__, __LINE__,aColor);
#endif
    
    [selectionColor release];
    [aColor retain];
    selectionColor=aColor;
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}


- (NSFont *)font
{
    return font;
}

- (NSFont *)nafont
{
    return nafont;
}

- (void) setFont:(NSFont*)aFont nafont:(NSFont *)naFont;
{    
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSSize sz;
	
    [dic setObject:aFont forKey:NSFontAttributeName];
    sz = [@"W" sizeWithAttributes:dic];
	
	charWidthWithoutSpacing = sz.width;
	charHeightWithoutSpacing = [aFont defaultLineHeightForFont];
	
    [font release];
    [aFont retain];
    font=aFont;
    [nafont release];
    [naFont retain];
    nafont=naFont;
    [self setMarkedTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor yellowColor], NSBackgroundColorAttributeName,
            [NSColor blackColor], NSForegroundColorAttributeName,
            font, NSFontAttributeName,
            [NSNumber numberWithInt:2],NSUnderlineStyleAttributeName,
            NULL]];
	[self resetCharCache];
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (void) resetCharCache
{
	int loop;
	for (loop=0;loop<CACHESIZE;loop++)
    {
		[charImages[loop].image release];
		charImages[loop].image=nil;
    }
}

- (id) dataSource
{
    return (dataSource);
}

- (void) setDataSource: (id) aDataSource
{
    dataSource = aDataSource;
}

- (id) delegate
{
    return _delegate;
}

- (void) setDelegate: (id) aDelegate
{
    _delegate = aDelegate;
}    

- (float) lineHeight
{
    return (lineHeight);
}

- (void) setLineHeight: (float) aLineHeight
{
    lineHeight = aLineHeight;
}

- (float) lineWidth
{
    return (lineWidth);
}

- (void) setLineWidth: (float) aLineWidth
{
    lineWidth = aLineWidth;
}

- (float) charWidth
{
	return (charWidth);
}

- (void) setCharWidth: (float) width
{
	charWidth = width;
}

- (void) setForceUpdate: (BOOL) flag
{
	forceUpdate = flag;
}


// We override this method since both refresh and window resize can conflict resulting in this happening twice
// So we do not allow the size to be set larger than what the data source can fill
- (void) setFrameSize: (NSSize) aSize
{
	//NSLog(@"%s (0x%x): setFrameSize to (%f,%f)", __PRETTY_FUNCTION__, self, aSize.width, aSize.height);

	NSSize anotherSize = aSize;
	
	anotherSize.height = [dataSource numberOfLines] * lineHeight;
	
	[super setFrameSize: anotherSize];
	
	// reset tracking rect
	if(trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:[self visibleRect] owner: self userData: nil assumeInside: NO];
}

- (void) refresh
{
	//NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);

    NSSize aSize;
	int height;
    
    if(dataSource != nil)
    {
		[dataSource acquireLock];
		
        numberOfLines = [dataSource numberOfLines];
        aSize = [self frame].size;
        height = numberOfLines * lineHeight;
        if(height != [self frame].size.height)
        {
            NSRect aFrame;
            
			//NSLog(@"%s: 0x%x; new number of lines = %d; resizing height from %f to %d", 
			//	  __PRETTY_FUNCTION__, self, numberOfLines, [self frame].size.height, height);
            aFrame = [self frame];
            aFrame.size.height = height;
            [self setFrame: aFrame];
			if (![(PTYScroller *)([[self enclosingScrollView] verticalScroller]) userScroll]) [self scrollEnd];
        }
		
		[self setNeedsDisplay: YES];

		[dataSource releaseLock];
    }
	
	
}


- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView adjustScroll]", __FILE__, __LINE__ );
#endif
	//forceUpdate = YES;
	proposedVisibleRect.origin.y=(int)(proposedVisibleRect.origin.y/lineHeight+0.5)*lineHeight;

    NSRect currentRect;    
    currentRect= [self visibleRect];
    
    int i, line;
    int lineNum = (proposedVisibleRect.origin.y - currentRect.origin.y)/lineHeight;
    for(i=lineNum-1; i>=0; i--) {
        line = (currentRect.origin.y+currentRect.size.height)/lineHeight + i -[dataSource numberOfLines]+[dataSource height];
        if (line>0) memset([dataSource dirty]+line*[dataSource width]*sizeof(char), 1, [dataSource width]*sizeof(char));
        else break;
    }
    
	return proposedVisibleRect;
}

-(void) scrollLineUpWithoutMoving
{
    NSRect scrollRect;
    float yOffset = [[self enclosingScrollView] verticalLineScroll];
    
    scrollRect = [self visibleRect];
    scrollRect.origin.y += yOffset;
    //NSLog(@"%f/%f",[[self enclosingScrollView] verticalLineScroll],[[self enclosingScrollView] verticalPageScroll]);
    [self scrollRect: scrollRect by:NSMakeSize(0, -yOffset)];
} 

-(void) scrollLineUp: (id) sender
{
    NSRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y-=[[self enclosingScrollView] verticalLineScroll];
	//forceUpdate = YES;
	//[self setNeedsDisplay: YES];
    //NSLog(@"%f/%f",[[self enclosingScrollView] verticalLineScroll],[[self enclosingScrollView] verticalPageScroll]);
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollLineDown: (id) sender
{
    NSRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y+=[[self enclosingScrollView] verticalLineScroll];
	//forceUpdate = YES;
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollPageUp: (id) sender
{
    NSRect scrollRect;
	
    scrollRect= [self visibleRect];
    scrollRect.origin.y-=[[self enclosingScrollView] verticalPageScroll];
	//forceUpdate = YES;
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollPageDown: (id) sender
{
    NSRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y+=[[self enclosingScrollView] verticalPageScroll];
	//forceUpdate = YES;
    [self scrollRectToVisible: scrollRect];
}

-(void) scrollHome
{
    NSRect scrollRect;
    
    scrollRect= [self visibleRect];
    scrollRect.origin.y = 0;
	//forceUpdate = YES;
    [self scrollRectToVisible: scrollRect];
}

- (void)scrollEnd
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView scrollEnd]", __FILE__, __LINE__ );
#endif
    
    if (numberOfLines > 0)
    {
        NSRect aFrame;
		aFrame.origin.x = 0;
		aFrame.origin.y = (numberOfLines - 1) * lineHeight;
		aFrame.size.width = [self frame].size.width;
		aFrame.size.height = lineHeight;
		//forceUpdate = YES;
		[self scrollRectToVisible: aFrame];
    }
}

- (void)scrollToSelection
{
	NSRect aFrame;
	aFrame.origin.x = 0;
	aFrame.origin.y = startY * lineHeight;
	aFrame.size.width = [self frame].size.width;
	aFrame.size.height = (endY - startY + 1) *lineHeight;
	//forceUpdate = YES;
	[self scrollRectToVisible: aFrame];
}

-(void) hideCursor
{
    CURSOR=NO;
}

-(void) showCursor
{
    CURSOR=YES;
}

- (void)drawRect:(NSRect)rect
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(0x%x):-[PTYTextView drawRect:(%f,%f,%f,%f) frameRect: (%f,%f,%f,%f)]",
          __PRETTY_FUNCTION__, self,
          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
		  [self frame].origin.x, [self frame].origin.y, [self frame].size.width, [self frame].size.height);
#endif
		
    int numLines, i, j, lineOffset, WIDTH;
	int startScreenLineIndex,line;
    screen_char_t *theLine;
	NSRect bgRect;
	NSColor *aColor;
	char  *dirty = NULL;
	BOOL need_draw;
	int bgstart, ulstart;
    float curX, curY;
	unsigned int bgcode = 0, fgcode = 0;
	int y1, x1;
	BOOL double_width;
	BOOL reversed = [[dataSource terminal] screenMode]; 
    struct timeval now;
    
    float trans = useTransparency ? 1.0 - transparency : 1.0;
    
    if(lineHeight <= 0 || lineWidth <= 0)
        return;
    
	// get lock on source 
    [dataSource acquireLock];
	
    gettimeofday(&now, NULL);
    if (now.tv_sec*10+now.tv_sec/100000 >= lastBlink.tv_sec*10+lastBlink.tv_sec/100000+5) {
        blinkShow = !blinkShow;
        lastBlink = now;
    }
    
	// make sure margins are filled in
	if (forceUpdate) {
		if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil)
		{
			[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: rect];
		}
		else {
			aColor = [self colorForCode:(reversed ? DEFAULT_FG_COLOR_CODE : DEFAULT_BG_COLOR_CODE)];
			aColor = [aColor colorWithAlphaComponent: trans];
			[aColor set];
			NSRectFill(rect);
		}
	}
		
	WIDTH=[dataSource width];

	// Starting from which line?
	lineOffset = rect.origin.y/lineHeight;
    
	// How many lines do we need to draw?
	numLines = rect.size.height/lineHeight;

	// Which line is our screen start?
	startScreenLineIndex=[dataSource numberOfLines] - [dataSource height];
    //NSLog(@"%f+%f->%d+%d", rect.origin.y,rect.size.height,lineOffset,numLines);
		
    // [self adjustScroll] should've made sure we are at an integer multiple of a line
	curY=rect.origin.y +lineHeight;
	
	// redraw margins if we have a background image, otherwise we can still "see" the margin
	if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil)
	{
		bgRect = NSMakeRect(0, rect.origin.y, MARGIN, rect.size.height);
		[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
		bgRect = NSMakeRect(rect.size.width - MARGIN, rect.origin.y, MARGIN, rect.size.height);
		[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
	}
	
      
    for(i = 0; i < numLines; i++)
    {
		curX = MARGIN;
        line = i + lineOffset;
		
		if(line >= [dataSource numberOfLines])
		{
			NSLog(@"%s (0x%x): illegal line index %d >= %d", __PRETTY_FUNCTION__, self, line, [dataSource numberOfLines]);
			[dataSource releaseLock];
			return;
		}
		
		// get the line
		theLine = [dataSource getLineAtIndex:line];
		//NSLog(@"the line = '%@'", [dataSource getLineString:theLine]);
		
		// Check if we are drawing a line in scrollback buffer
		if (line < startScreenLineIndex) 
		{
			//NSLog(@"Buffer: %d",line);
		}
		else 
		{ 
			// get the dirty flags
			dirty=[dataSource dirty]+(line-startScreenLineIndex)*WIDTH;
			//NSLog(@"Screen: %d",(line-startScreenLineIndex));
		}	
		
		//draw background and underline here
		bgstart = ulstart = -1;
		
		for(j = 0; j < WIDTH; j++) 
		{
			if (theLine[j].ch == 0xffff) 
				continue;
			
			// Check if we need to redraw the char
			need_draw = line < startScreenLineIndex || forceUpdate || dirty[j] || (theLine[j].fg_color & BLINK_MASK);

			// if we don't have to update next char, finish pending jobs
			if (!need_draw)
			{
				if (bgstart >= 0) 
				{
					aColor = (bgcode & SELECTION_MASK) ? selectionColor : 
						[self colorForCode: 
							((reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode)]; 
					aColor = [aColor colorWithAlphaComponent: trans];
					[aColor set];
					
					bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
					NSRectFill(bgRect);
					// if we have a background image and we are using the background image, redraw image
					if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil && bgcode == DEFAULT_BG_COLOR_CODE)
					{
						[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
					}
					
				}						
				if (ulstart >= 0) 
				{
					[[self colorForCode:(fgcode & 0x3f)] set];
					NSRectFill(NSMakeRect(floor(curX+ulstart*charWidth),curY-2,ceil((j-ulstart)*charWidth),1));
				}
				bgstart = ulstart = -1;
			}
			else 
			{
				// find out if the current char is being selected
				if (bgstart < 0) {
					bgstart = j; 
					bgcode = theLine[j].bg_color & 0xff; 
				}
				else if (theLine[j].bg_color != bgcode || (ulstart >= 0 && (theLine[j].fg_color != fgcode || !(theLine[j].ch)))) 
				{ 
					//background or underline property change?
					aColor = (bgcode & SELECTION_MASK) ? selectionColor : 
						[self colorForCode: 
							((reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode)]; 
					aColor = [aColor colorWithAlphaComponent: trans];
					[aColor set];
					
					bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
					NSRectFill(bgRect);
					if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil && bgcode == DEFAULT_BG_COLOR_CODE)
					{
						[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
					}
					bgstart = j; 
					bgcode = theLine[j].bg_color & 0xff; 
				}
				
				if (ulstart < 0 && (theLine[j].fg_color & UNDER_MASK) && theLine[j].ch) 
				{ 
					ulstart = j;
					fgcode = theLine[j].fg_color & 0xff; 
				}
				else if (ulstart >= 0 && (theLine[j].fg_color != fgcode || !(theLine[j].ch))) 
				{ 
					//underline or fg color property change?
					[[self colorForCode:(fgcode & 0x3f)] set];
					NSRectFill(NSMakeRect(floor(curX+ulstart*charWidth),curY-2,ceil((j-ulstart)*charWidth),1));
					fgcode = theLine[j].fg_color & 0xff;
					ulstart = (theLine[j].fg_color & UNDER_MASK && theLine[j].ch)?j:-1;
				}
			}
		}
		
		// finish pending jobs
		if (bgstart >= 0) 
		{
			aColor = (bgcode & SELECTION_MASK) ? selectionColor : 
				[self colorForCode: 
					((reversed && bgcode == DEFAULT_BG_COLOR_CODE) ? DEFAULT_FG_COLOR_CODE: bgcode)]; 
			aColor = [aColor colorWithAlphaComponent: trans];
			[aColor set];
			
			bgRect = NSMakeRect(floor(curX+bgstart*charWidth),curY-lineHeight,ceil((j-bgstart)*charWidth),lineHeight);
			NSRectFill(bgRect);
			if([(PTYScrollView *)[self enclosingScrollView] backgroundImage] != nil && bgcode == DEFAULT_BG_COLOR_CODE)
			{
				[(PTYScrollView *)[self enclosingScrollView] drawBackgroundImageRect: bgRect];
			}
		}
		
		if (ulstart >= 0) 
		{
			[[self colorForCode:fgcode] set];
			NSRectFill(NSMakeRect(floor(curX+ulstart*charWidth),curY-2,ceil((j-ulstart)*charWidth),1));
		}
		
		//draw all char
		for(j = 0; j < WIDTH; j++) 
		{
			need_draw = (theLine[j].ch && theLine[j].ch != 0xffff) && 
				(line < startScreenLineIndex || forceUpdate || dirty[j] || (theLine[j].fg_color & BLINK_MASK));
			if (need_draw) 
			{ 
				double_width = (theLine[j+1].ch == 0xffff);
				// switch colors if text is selected
				if((theLine[j].bg_color & SELECTION_MASK) && ((theLine[j].fg_color & 0x1f) == DEFAULT_FG_COLOR_CODE))
					fgcode = SELECTED_TEXT | ((theLine[j].fg_color & BOLD_MASK) & 0xff); // check for bold
				else
					fgcode = (reversed && theLine[j].fg_color & DEFAULT_FG_COLOR_CODE) ? 
						(DEFAULT_BG_COLOR_CODE | (theLine[j].fg_color & BOLD_MASK)) : (theLine[j].fg_color & 0xff);
				if (theLine[j].fg_color & BLINK_MASK) 
				{
					if (blinkShow) 
					{				
						[self _drawCharacter:theLine[j].ch fgColor:fgcode AtX:curX Y:curY doubleWidth: double_width];
					}
				}
				else 
				{
					[self _drawCharacter:theLine[j].ch fgColor:fgcode AtX:curX Y:curY doubleWidth: double_width];
					if(line >= startScreenLineIndex) 
						dirty[j]=0;
				}
			}
			else if(line >= startScreenLineIndex) 
				dirty[j]=0;
			
			curX+=charWidth;
		}
		//if (line>=startScreenLineIndex) memset(dirty,0,WIDTH);
		curY+=lineHeight;
	}
	
	
    // Double check if dataSource is still available
    if (!dataSource) return;
	
	x1=[dataSource cursorX]-1;
	y1=[dataSource cursorY]-1;
	
	//draw cursor	
	float cursorWidth, cursorHeight;				
				
	if(charWidth < charWidthWithoutSpacing)
		cursorWidth = charWidth;
	else
		cursorWidth = charWidthWithoutSpacing;
	
	if(lineHeight < charHeightWithoutSpacing)
		cursorHeight = lineHeight;
	else
		cursorHeight = charHeightWithoutSpacing;
	
	if([self blinkingCursor] && [[self window] isKeyWindow] && x1==oldCursorX && y1==oldCursorY)
		showCursor = blinkShow;
	else
		showCursor = YES;

    oldCursorX = x1;
    oldCursorY = y1;
	if (CURSOR) {
		i = y1*[dataSource width]+x1;
		// get the cursor line
		theLine = [dataSource getLineAtScreenIndex: y1];
		if(showCursor)
		{			
			[[[self defaultCursorColor] colorWithAlphaComponent: trans] set];

			if([[self window] isKeyWindow])
			{
				NSRectFill(NSMakeRect(floor(x1 * charWidth + MARGIN),
									  (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
									  ceil(cursorWidth), cursorHeight));
			}
			else
			{
				NSFrameRect(NSMakeRect(floor(x1 * charWidth + MARGIN),
									  (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
									  ceil(cursorWidth), cursorHeight));
				
			}
			// draw any character on cursor if we need to
			unichar aChar = theLine[x1].ch;
			if (aChar)
			{
				if (aChar == 0xffff && x1>0) 
				{
					i--;
					x1--;
					aChar = theLine[x1].ch;
				}
				double_width = (theLine[x1+1].ch == 0xffff);
				[self _drawCharacter: aChar 
							 fgColor: [[self window] isKeyWindow]?CURSOR_TEXT:(theLine[x1].fg_color & 0xff)
								AtX: x1 * charWidth + MARGIN 
								  Y: (y1+[dataSource numberOfLines]-[dataSource height]+1)*lineHeight
						doubleWidth: double_width];
			}
		}
		[dataSource dirty][i] = 1; //cursor loc is dirty
		
	}
	
	// draw any text for NSTextInput
	if([self hasMarkedText]) {
		int len;
		
		len=[markedText length];
		if (len>[dataSource width]-x1) len=[dataSource width]-x1;
		[markedText drawInRect:NSMakeRect(floor(x1 * charWidth + MARGIN),
										  (y1+[dataSource numberOfLines]-[dataSource height])*lineHeight + (lineHeight - cursorHeight),
										  ceil((WIDTH-x1)*cursorWidth),cursorHeight)];
		memset([dataSource dirty]+y1*[dataSource width]+x1, 1,len*2); //len*2 is an over-estimation, but safe
	}
	

	forceUpdate=NO;
    [dataSource releaseLock];
	
}

- (void)keyDown:(NSEvent *)event
{
    NSInputManager *imana = [NSInputManager currentInputManager];
    BOOL IMEnable = [imana wantsToInterpretAllKeystrokes];
    id delegate = [self delegate];
	unsigned int modflag = [event modifierFlags];
    BOOL prev = [self hasMarkedText];
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView keyDown:%@]",
          __FILE__, __LINE__, event );
#endif
    
	keyIsARepeat = [event isARepeat];
	
    // Hide the cursor
    [NSCursor setHiddenUntilMouseMoves: YES];   
	
	// Check whether we have a custom mapping for this event or if numeric or function keys were pressed.
	if ( prev == NO && 
		 ([delegate hasKeyMappingForEvent: event] ||
		  (modflag & NSNumericPadKeyMask) || 
		  (modflag & NSFunctionKeyMask)))
	{
		[delegate keyDown:event];
		return;
	}
	
    IM_INPUT_INSERT = NO;
    if (IMEnable) {
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
        
        if (prev == NO &&
            IM_INPUT_INSERT == NO &&
            [self hasMarkedText] == NO)
        {
            [delegate keyDown:event];
        }
    }
    else {

		if([[self delegate] optionKey] == OPT_NORMAL)
		{
			[self interpretKeyEvents:[NSArray arrayWithObject:event]];
		}
		
		if (IM_INPUT_INSERT == NO) {
			[delegate keyDown:event];
		}
    }
}

- (BOOL) keyIsARepeat
{
	return (keyIsARepeat);
}

- (void) otherMouseDown: (NSEvent *) event
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: %@]", __PRETTY_FUNCTION__, sender );
#endif

    NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y))
		//		&& ([event modifierFlags] & NSCommandKeyMask == 0)) 
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];

		int bnum = [event buttonNumber];
		if (bnum == 2) bnum = 1;
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				reportingMouseDown = YES;
				[task writeTask:[terminal mousePress:bnum withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	
	if([[PreferencePanel sharedInstance] pasteFromClipboard])
		[self paste: nil];
	else
		[self pasteSelection: nil];
}

- (void)otherMouseUp:(NSEvent *)event
{
	NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& reportingMouseDown)
	{
		reportingMouseDown = NO;
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseReleaseAtX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}	
	[super otherMouseUp:event];
}

- (void)otherMouseDragged:(NSEvent *)event
{
    NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y)
		&& reportingMouseDown)
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		int bnum = [event buttonNumber];
		if (bnum == 2) bnum = 1;
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseMotion:bnum withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	[super otherMouseDragged:event];
}

- (void) rightMouseDown: (NSEvent *) event
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: %@]", __PRETTY_FUNCTION__, sender );
#endif
	
    NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y))
		//		&& ([event modifierFlags] & NSCommandKeyMask == 0)) 
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				reportingMouseDown = YES;
				[task writeTask:[terminal mousePress:2 withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	[super rightMouseDown:event];
}

- (void)rightMouseUp:(NSEvent *)event
{
	NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& reportingMouseDown)
	{
		reportingMouseDown = NO;
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseReleaseAtX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}	
	[super rightMouseUp:event];
}

- (void)rightMouseDragged:(NSEvent *)event
{
    NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y)
		&& reportingMouseDown)
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseMotion:2 withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	[super rightMouseDragged:event];
}

- (void)scrollWheel:(NSEvent *)event
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: %@]", __PRETTY_FUNCTION__, sender );
#endif
	
    NSPoint locationInWindow, locationInTextView;
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
	
	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y))
		//		&& ([event modifierFlags] & NSCommandKeyMask == 0)) 
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mousePress:([event deltaY] > 0 ? 5:4) withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	[super scrollWheel:event];	
}

- (void)mouseExited:(NSEvent *)event
{
	//NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
	// no-op
}

- (void)mouseEntered:(NSEvent *)event
{
	//NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
	
	if([[PreferencePanel sharedInstance] focusFollowsMouse])
		[[self window] makeKeyWindow];
}

- (void)mouseDown:(NSEvent *)event
{
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView mouseDown:%@]",
          __FILE__, __LINE__, event );
#endif
    
    NSPoint locationInWindow, locationInTextView;
    int x, y;
    int width = [dataSource width];
	
    locationInWindow = [event locationInWindow];
    locationInTextView = [self convertPoint: locationInWindow fromView: nil]; 
    
    x = (locationInTextView.x-MARGIN)/charWidth;
	if (x<0) x=0;
    y = locationInTextView.y/lineHeight;
	
    if (x>=width) x = width  - 1;

	NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
	if (([[self delegate] xtermMouseReporting]) 
		&& (locationInTextView.y > visibleRect.origin.y))
	{
		int rx, ry;
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				reportingMouseDown = YES;
				[task writeTask:[terminal mousePress:0 withModifiers:[event modifierFlags] atX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	
	if(mouseDownEvent != nil)
    {
		[mouseDownEvent release];
		mouseDownEvent = nil;
    }	
    [event retain];
    mouseDownEvent = event;
	
	
	mouseDragged = NO;
	mouseDown = YES;
	mouseDownOnSelection = NO;
    
    if ([event clickCount]<2 ) {
        selectMode = SELECT_CHAR;

        // if we are holding the shift key down, we are extending selection
        if (startX > -1 && ([event modifierFlags] & NSShiftKeyMask))
        {
            if (x+y*width<startX+startY*width) {
                startX = endX;
                startY = endY;
            }
            endX = x;
            endY = y;
        }
		// check if we clicked inside a selection for a possible drag
		else if(startX > -1 && [self _mouseDownOnSelection: event] == YES)
		{
			mouseDownOnSelection = YES;
			[super mouseDown: event];
			return;
		}
        else if (!([event modifierFlags] & NSCommandKeyMask))
        {
            endX = startX = x;
            endY = startY = y;
        }	
    }
	// Handle double and triple click
	else if([event clickCount] == 2)
	{
        int tmpX1, tmpY1, tmpX2, tmpY2;
        
        // double-click; select word
        selectMode = SELECT_WORD;
		[self _getWordForX: x y: y startX: &tmpX1 startY: &tmpY1 endX: &tmpX2 endY: &tmpY2];
        if (startX > -1 && ([event modifierFlags] & NSShiftKeyMask))
        {
            if (startX+startY*width<tmpX1+tmpY1*width) {
                endX = tmpX2;
                endY = tmpY2;	
            }
            else {
                startX = endX;
                startY = endY;
                endX = tmpX1;
                endY = tmpY1;
            }
        }
        else 
        {
            startX = tmpX1;
            startY = tmpY1;
            endX = tmpX2;
            endY = tmpY2;	
        }
	}
	else if ([event clickCount] >= 3)
	{
        // triple-click; select line
        selectMode = SELECT_LINE;
        if (startX > -1 && ([event modifierFlags] & NSShiftKeyMask))
        {
            if (startY<y) {
                endX = width - 1;
                endY = y;
            }
            else {
                if (startX+startY*width<endX+endY*width) {
                    startX = endX;
                    startY = endY;
                }
                endX = 0;
                endY = y;
            }
        }
        else
        {
            startX = 0;
            endX = width - 1;
            startY = endY = y;
        }            
	}
	    
    if (startX>-1 && (startX != endX || startY!=endY)) 
        [self _selectFromX:startX Y:startY toX:endX Y:endY];

    if([_delegate respondsToSelector: @selector(willHandleEvent:)] && [_delegate willHandleEvent: event])
        [_delegate handleEvent: event];
	[self setNeedsDisplay: YES];
	
}

- (void)mouseUp:(NSEvent *)event
{	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView mouseUp:%@]",
          __FILE__, __LINE__, event );
#endif
	NSPoint locationInWindow = [event locationInWindow];
    NSPoint locationInTextView = [self convertPoint: locationInWindow fromView: nil];
	int x, y;
	int width = [dataSource width];
	
    x = (locationInTextView.x - MARGIN) / charWidth;
	if (x < 0) x = 0;
	if (x>=width) x = width - 1;
	
    
	y = locationInTextView.y/lineHeight;
	
	
	if ([[self delegate] xtermMouseReporting]
		&& reportingMouseDown) 
	{
		reportingMouseDown = NO;
		int rx, ry;
		NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_NORMAL:
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseReleaseAtX:rx Y:ry]];
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	
	if(mouseDown == NO)
		return;
	mouseDown = NO;
		
	// make sure we have key focus
	[[self window] makeFirstResponder: self];
    
    if (startY>endY||(startY==endY&&startX>endX)) {
        int t;
        t=startY; startY=endY; endY=t;
        t=startX; startX=endX; endX=t;
    }
    else if ([mouseDownEvent locationInWindow].x == [event locationInWindow].x &&
			 [mouseDownEvent locationInWindow].y == [event locationInWindow].y && 
			 !([event modifierFlags] & NSCommandKeyMask) && 
             !([event modifierFlags] & NSShiftKeyMask) &&
			 [event clickCount] < 2 && !mouseDragged) 
	{		
		startX=-1;
	}
	
	// if we are on an empty line, we select the current line to the end
	//if([self _isBlankLine: y] && y >= 0)
	//  endX = [dataSource width] - 1;
	
	
	[self _selectFromX:startX Y:startY toX:endX Y:endY];
    if (startX!=-1&&_delegate) {
		// if we want to copy our selection, do so
        if([[PreferencePanel sharedInstance] copySelection])
            [self copy: self];
        // handle command click on URL
        if(([event modifierFlags] & NSCommandKeyMask) && [[PreferencePanel sharedInstance] cmdSelection] &&
		   [mouseDownEvent locationInWindow].x == [event locationInWindow].x &&
		   [mouseDownEvent locationInWindow].y == [event locationInWindow].y)
        {
            [self _openURL: [self selectedText]];
        }
    }
	
    selectMode = SELECT_CHAR;
	[self setNeedsDisplay: YES];
}

- (void)mouseDragged:(NSEvent *)event
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView mouseDragged:%@; modifier flags = 0x%x]",
          __FILE__, __LINE__, event, [event modifierFlags] );
#endif
    NSPoint locationInWindow = [event locationInWindow];
    NSPoint locationInTextView = [self convertPoint: locationInWindow fromView: nil];
    NSRect  rectInTextView = [self visibleRect];
    int x, y, tmpX1, tmpX2, tmpY1, tmpY2;
    int width = [dataSource width];
	NSString *theSelectedText;
	
    x = (locationInTextView.x - MARGIN) / charWidth;
	if (x < 0) x = 0;
	if (x>=width) x = width - 1;
	
    
	y = locationInTextView.y/lineHeight;
	
	if (([[self delegate] xtermMouseReporting])
		&& reportingMouseDown) 
	{
		int rx, ry;
		NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
		rx = (locationInTextView.x-MARGIN - visibleRect.origin.x)/charWidth;
		ry = (locationInTextView.y - visibleRect.origin.y)/lineHeight;
		if (rx < 0) rx = -1;
		if (ry < 0) ry = -1;
		VT100Terminal *terminal = [dataSource terminal];
		PTYTask *task = [dataSource shellTask];
		
		switch ([terminal mouseMode]) {
			case MOUSE_REPORTING_BUTTON_MOTION:
			case MOUSE_REPORTING_ALL_MOTION:
				[task writeTask:[terminal mouseMotion:0 withModifiers:[event modifierFlags] atX:rx Y:ry]];
			case MOUSE_REPORTING_NORMAL:
				return;
				break;
			case MOUSE_REPORTING_NONE:
			case MOUSE_REPORTING_HILITE:
				// fall through
				break;
		}
	}
	
	mouseDragged = YES;
	
	// check if we want to drag and drop a selection
	if(mouseDownOnSelection == YES)
	{
		theSelectedText = [self contentFromX: startX Y: startY ToX: endX Y: endY breakLines: YES pad: NO];
		if([theSelectedText length] > 0)
		{
			[self _dragText: theSelectedText forEvent: event];
			return;
		}
	}
    
	// NSLog(@"(%f,%f)->(%f,%f)",locationInWindow.x,locationInWindow.y,locationInTextView.x,locationInTextView.y); 
    if (locationInTextView.y<rectInTextView.origin.y) {
        rectInTextView.origin.y=locationInTextView.y;
        [self scrollRectToVisible: rectInTextView];
    }
    else if (locationInTextView.y>rectInTextView.origin.y+rectInTextView.size.height) {
        rectInTextView.origin.y+=locationInTextView.y-rectInTextView.origin.y-rectInTextView.size.height;
        [self scrollRectToVisible: rectInTextView];
    }
    
	// if we are on an empty line, we select the current line to the end
	if([self _isBlankLine: y] && y >= 0)
		x = width - 1;
	
	if(locationInTextView.x < MARGIN && startY < y)
	{
		// complete selection of previous line
		x = width - 1;
		y--;
	}
    if (y<0) y=0;
    if (y>=[dataSource numberOfLines]) y=numberOfLines - 1;
    
    switch (selectMode) {
        case SELECT_CHAR:
            endX=x;
            endY=y;
            break;
        case SELECT_WORD:
            [self _getWordForX: x y: y startX: &tmpX1 startY: &tmpY1 endX: &tmpX2 endY: &tmpY2];
            if (startX+startY*width<tmpX2+tmpY2*width) {
                if (startX+startY*width>endX+endY*width) {
                    int tx1, tx2, ty1, ty2;
                    [self _getWordForX: startX y: startY startX: &tx1 startY: &ty1 endX: &tx2 endY: &ty2];
                    startX = tx1;
                    startY = ty1;
                }
                endX = tmpX2;
                endY = tmpY2;
            }
            else {
                if (startX+startY*width<endX+endY*width) {
                    int tx1, tx2, ty1, ty2;
                    [self _getWordForX: startX y: startY startX: &tx1 startY: &ty1 endX: &tx2 endY: &ty2];
                    startX = tx2;
                    startY = ty2;
                }
                endX = tmpX1;
                endY = tmpY1;
            }
            break;
        case SELECT_LINE:
            if (startY <= y) {
                startX = 0;
                endX = [dataSource width] - 1;
                endY = y;
            }
            else {
                endX = 0;
                endY = y;
                startX = [dataSource width] - 1;
            }
            break;
    }
            
    [self _selectFromX:startX Y:startY toX:endX Y:endY];
	[self setNeedsDisplay: YES];
	//NSLog(@"(%d,%d)-(%d,%d)",startX,startY,endX,endY);
}

- (NSString *) contentFromX:(int)startx Y:(int)starty ToX:(int)endx Y:(int)endy breakLines: (BOOL) breakLines pad: (BOOL) pad
{
	unichar *temp;
	int j;
	int width, y, x1, x2;
	NSString *str;
	screen_char_t *theLine;
	BOOL endOfLine;
	int i;
	
	width = [dataSource width];
	temp = (unichar *) malloc(((endy-starty+1)*(width+1)+(endx-startx+1))*sizeof(unichar));
	j = 0;
	for (y = starty; y <= endy; y++) 
	{
		theLine = [dataSource getLineAtIndex:y];

		x1=0; 
		x2=width - 1;
		if (y == starty) 
			x1 = startx;
		if (y == endy) 
			x2=endx;
		for(; x1 <= x2; x1++) 
		{
			if (theLine[x1].ch != 0xffff) 
			{
				temp[j] = theLine[x1].ch;
				if(theLine[x1].ch == 0) // end of line?
				{
					// if there is no text after this, insert a hard line break
					endOfLine = YES;
					for(i = x1+1; i <= x2; i++)
					{
						if(theLine[i].ch != 0)
							endOfLine = NO;
					}
					if(endOfLine && !pad && y < endy)
					{
						temp[j] = '\n'; // hard break
						j++;
						break; // continue to next line
					}
					else if (endOfLine && (y == endy))
						break;
					else
						temp[j] = ' '; // represent blank with space
				}
				else if (x1 == x2 && breakLines && y < endy) // definitely end of line
				{
					temp[j+1] = '\n'; // hard break
					j += 2;
					break; // continue to next line
				}
				j++;
			}
		}		
	}
	
	str=[NSString stringWithCharacters:temp length:j];
	free(temp);
	
	return str;
}

- (IBAction) selectAll: (id) sender
{
	// set the selection region for the whole text
	startX = startY = 0;
	endX = [dataSource width] - 1;
	endY = [dataSource numberOfLines] - 1;
	[self _selectFromX:startX Y:startY toX:endX Y:endY];
	[self setNeedsDisplay: YES];
}

- (NSString *) selectedText
{
	return [self selectedTextBreakingLines: NO pad: NO];
}


- (NSString *) selectedTextBreakingLines: (BOOL) breakLines pad: (BOOL) pad
{
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s]", __PRETTY_FUNCTION__);
#endif
	
	if (startX == -1) return nil;
	
	return ([self contentFromX: startX Y: startY ToX: endX Y: endY breakLines: breakLines pad: pad]);
	
}

- (NSString *) content
{
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView copy:%@]", __FILE__, __LINE__, sender );
#endif
    	
	return [self contentFromX:0 Y:0 ToX:[dataSource width]-1 Y:[dataSource numberOfLines]-1 breakLines: YES pad: NO];
}

- (void) copy: (id) sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSString *copyString;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView copy:%@]", __FILE__, __LINE__, sender );
#endif
    
    copyString=[self selectedText];
    
    if (copyString && [copyString length]>0) {
        [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: self];
        [pboard setString: copyString forType: NSStringPboardType];
    }
}

- (void)paste:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView paste:%@]", __FILE__, __LINE__, sender );
#endif
    
    if ([_delegate respondsToSelector:@selector(paste:)])
        [_delegate paste:sender];
}

- (void) pasteSelection: (id) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: %@]", __PRETTY_FUNCTION__, sender );
#endif
    
    if (startX >= 0 && [_delegate respondsToSelector:@selector(pasteString:)])
        [_delegate pasteString:[self selectedText]];
	
}


- (BOOL)validateMenuItem:(NSMenuItem *)item
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView validateMenuItem:%@; supermenu = %@]", __FILE__, __LINE__, item, [[item menu] supermenu] );
#endif
    	
    if ([item action] == @selector(paste:))
    {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        
        // Check if there is a string type on the pasteboard
        return ([pboard stringForType:NSStringPboardType] != nil);
    }
    else if ([item action ] == @selector(cut:))
        return NO;
    else if ([item action]==@selector(saveDocumentAs:) ||
			 [item action] == @selector(selectAll:) || 
			 ([item action] == @selector(print:) && [item tag] != 1))
    {
        // We always validate the above commands
        return (YES);
    }
    else if ([item action]==@selector(mail:) ||
             [item action]==@selector(browse:) ||
             [item action]==@selector(copy:) ||
			 [item action]==@selector(pasteSelection:) || 
			 ([item action]==@selector(print:) && [item tag] == 1)) // print selection
    {
        //        NSLog(@"selected range:%d",[self selectedRange].length);
        return (startX>=0);
    }
    else
        return NO;
}

- (void)changeFont:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView changeFont:%@]", __FILE__, __LINE__, sender );
#endif
    
    [super changeFont:sender];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSMenu *cMenu;
    
    // Allocate a menu
    cMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    
    // Menu items for acting on text selections
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"-> Browser",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(browse:) keyEquivalent:@""];
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"-> Mail",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(mail:) keyEquivalent:@""];
    
    // Separator
    [cMenu addItem:[NSMenuItem separatorItem]];
    
    // Copy,  paste, and save
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Copy",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(copy:) keyEquivalent:@""];
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Paste",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(paste:) keyEquivalent:@""];
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Save",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(saveDocumentAs:) keyEquivalent:@""];
    
    // Separator
    [cMenu addItem:[NSMenuItem separatorItem]];
    
    // Select all
    [cMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Select All",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu")
                     action:@selector(selectAll:) keyEquivalent:@""];
    
    
    // Ask the delegae if there is anything to be added
    if ([[self delegate] respondsToSelector:@selector(menuForEvent: menu:)])
        [[self delegate] menuForEvent:theEvent menu: cMenu];
    
    return [cMenu autorelease];
}

- (void) mail:(id)sender
{
	[self _openURL: [self selectedText]];
}

- (void) browse:(id)sender
{
	[self _openURL: [self selectedText]];
}

//
// Drag and Drop methods for our text view
//

//
// Called when our drop area is entered
//
- (unsigned int) draggingEntered:(id <NSDraggingInfo>)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView draggingEntered:%@]", __FILE__, __LINE__, sender );
#endif
    
    // Always say YES; handle failure later.
    bExtendedDragNDrop = YES;
    
    return bExtendedDragNDrop;
}

//
// Called when the dragged object is moved within our drop area
//
- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender
{
    unsigned int iResult;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView draggingUpdated:%@]", __FILE__, __LINE__, sender );
#endif
    
    // Let's see if our parent NSTextView knows what to do
    iResult = [super draggingUpdated: sender];
    
    // If parent class does not know how to deal with this drag type, check if we do.
    if (iResult == NSDragOperationNone) // Parent NSTextView does not support this drag type.
        return [self _checkForSupportedDragTypes: sender];
    
    return iResult;
}

//
// Called when the dragged object leaves our drop area
//
- (void) draggingExited:(id <NSDraggingInfo>)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView draggingExited:%@]", __FILE__, __LINE__, sender );
#endif
    
    // We don't do anything special, so let the parent NSTextView handle this.
    [super draggingExited: sender];
    
    // Reset our handler flag
    bExtendedDragNDrop = NO;
}

//
// Called when the dragged item is about to be released in our drop area.
//
- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    BOOL bResult;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView prepareForDragOperation:%@]", __FILE__, __LINE__, sender );
#endif
    
    // Check if parent NSTextView knows how to handle this.
    bResult = [super prepareForDragOperation: sender];
    
    // If parent class does not know how to deal with this drag type, check if we do.
    if ( bResult != YES && [self _checkForSupportedDragTypes: sender] != NSDragOperationNone )
        bResult = YES;
    
    return bResult;
}

//
// Called when the dragged item is released in our drop area.
//
- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    unsigned int dragOperation;
    BOOL bResult = NO;
    PTYSession *delegate = [self delegate];
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView performDragOperation:%@]", __FILE__, __LINE__, sender );
#endif
    
    // If parent class does not know how to deal with this drag type, check if we do.
    if (bExtendedDragNDrop)
    {
        NSPasteboard *pb = [sender draggingPasteboard];
        NSArray *propertyList;
        NSString *aString;
        int i;
        
        dragOperation = [self _checkForSupportedDragTypes: sender];
        
        switch (dragOperation)
        {
            case NSDragOperationCopy:
                // Check for simple strings first
                aString = [pb stringForType:NSStringPboardType];
                if (aString != nil)
                {
                    if ([delegate respondsToSelector:@selector(pasteString:)])
                        [delegate pasteString: aString];
                }
                    
                    // Check for file names
                    propertyList = [pb propertyListForType: NSFilenamesPboardType];
                for(i = 0; i < [propertyList count]; i++)
                {
                    
                    // Ignore text clippings
                    NSString *filename = (NSString*)[propertyList objectAtIndex: i]; // this contains the POSIX path to a file
                    NSDictionary *filenamesAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filename traverseLink:YES];
                    if (([filenamesAttributes fileHFSTypeCode] == 'clpt' &&
                         [filenamesAttributes fileHFSCreatorCode] == 'MACS') ||
                        [[filename pathExtension] isEqualToString:@"textClipping"] == YES)
                    {
                        continue;
                    }
                    
                    // Just paste the file names into the shell after escaping special characters.
                    if ([delegate respondsToSelector:@selector(pasteString:)])
                    {
                        NSMutableString *aMutableString;
                        
                        aMutableString = [[NSMutableString alloc] initWithString: (NSString*)[propertyList objectAtIndex: i]];
                        // get rid of special characters
                        [aMutableString replaceOccurrencesOfString: @"\\" withString: @"\\\\" options: 0 range: NSMakeRange(0, [aMutableString length])];
                        [aMutableString replaceOccurrencesOfString: @" " withString: @"\\ " options: 0 range: NSMakeRange(0, [aMutableString length])];
                        [aMutableString replaceOccurrencesOfString: @"(" withString: @"\\(" options: 0 range: NSMakeRange(0, [aMutableString length])];
                        [aMutableString replaceOccurrencesOfString: @")" withString: @"\\)" options: 0 range: NSMakeRange(0, [aMutableString length])];
                        [aMutableString replaceOccurrencesOfString: @"\"" withString: @"\\\"" options: 0 range: NSMakeRange(0, [aMutableString length])];
    [aMutableString replaceOccurrencesOfString: @"&" withString: @"\\&" options: 0 range: NSMakeRange(0, [aMutableString length])];
    [aMutableString replaceOccurrencesOfString: @"'" withString: @"\\'" options: 0 range: NSMakeRange(0, [aMutableString length])];

    [delegate pasteString: aMutableString];
    [delegate pasteString: @" "];
    [aMutableString release];
                    }

                }
    bResult = YES;
    break;				
        }

    }

    return bResult;
}

//
//
//
- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView concludeDragOperation:%@]", __FILE__, __LINE__, sender );
#endif
    
    // If we did no handle the drag'n'drop, ask our parent to clean up
    // I really wish the concludeDragOperation would have a useful exit value.
    if (!bExtendedDragNDrop)
        [super concludeDragOperation: sender];
    
    bExtendedDragNDrop = NO;
}

- (void)resetCursorRects
{
    static NSCursor *cursor=nil;
	//    NSLog(@"Setting mouse here");
    if (!cursor) cursor=[[NSCursor alloc] initWithImage:[[NSCursor arrowCursor] image] hotSpot:NSMakePoint(0,0)];
    [self addCursorRect:[self bounds] cursor:cursor];
    [cursor setOnMouseEntered:YES];
}

// Save method
- (void) saveDocumentAs: (id) sender
{
	
    NSData *aData;
    NSSavePanel *aSavePanel;
    NSString *aString;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView saveDocumentAs:%@]", __FILE__, __LINE__, sender );
#endif
    
    // We get our content of the textview or selection, if any
	aString = [self selectedText];
	if (!aString) aString = [self content];
    aData = [aString
            dataUsingEncoding: NSASCIIStringEncoding
         allowLossyConversion: YES];
    // retain here so that is does not go away...
    [aData retain];
    
    // initialize a save panel
    aSavePanel = [NSSavePanel savePanel];
    [aSavePanel setAccessoryView: nil];
    [aSavePanel setRequiredFileType: @""];
    
    // Run the save panel as a sheet
    [aSavePanel beginSheetForDirectory: @""
                                  file: @"Unknown"
                        modalForWindow: [self window]
                         modalDelegate: self
                        didEndSelector: @selector(_savePanelDidEnd: returnCode: contextInfo:)
                           contextInfo: aData];
}

// Print
- (void) print: (id) sender
{
	NSRect visibleRect;
	int lineOffset, numLines;
	
	switch ([sender tag])
	{
		case 0: // visible range
			visibleRect = [[self enclosingScrollView] documentVisibleRect];
			// Starting from which line?
			lineOffset = visibleRect.origin.y/lineHeight;			
			// How many lines do we need to draw?
			numLines = visibleRect.size.height/lineHeight;
			[self printContent: [self contentFromX: 0 Y: lineOffset 
											   ToX: [dataSource width] - 1 Y: lineOffset + numLines - 1
										breakLines: YES pad: NO]];
			break;
		case 1: // text selection
			[self printContent: [self selectedTextBreakingLines: YES pad: NO]];
			break;
		case 2: // entire buffer
			[self printContent: [self content]];
			break;
	}
}

- (void) printContent: (NSString *) aString
{
    NSPrintInfo *aPrintInfo;
	    
    aPrintInfo = [NSPrintInfo sharedPrintInfo];
    [aPrintInfo setHorizontalPagination: NSFitPagination];
    [aPrintInfo setVerticalPagination: NSAutoPagination];
    [aPrintInfo setVerticallyCentered: NO];
	
    // create a temporary view with the contents, change to black on white, and print it
    NSTextView *tempView;
    NSMutableAttributedString *theContents;
	
    tempView = [[NSTextView alloc] initWithFrame: [[self enclosingScrollView] documentVisibleRect]];
    theContents = [[NSMutableAttributedString alloc] initWithString: aString];
    [theContents addAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor textBackgroundColor], NSBackgroundColorAttributeName,
		[NSColor textColor], NSForegroundColorAttributeName, 
		[NSFont userFixedPitchFontOfSize: 0], NSFontAttributeName, NULL]
						 range: NSMakeRange(0, [theContents length])];
    [[tempView textStorage] setAttributedString: theContents];
    [theContents release];
	
    // now print the temporary view
    [[NSPrintOperation printOperationWithView: tempView  printInfo: aPrintInfo] runOperation];
    [tempView release];    
}

/// NSTextInput stuff
- (void)doCommandBySelector:(SEL)aSelector
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView doCommandBySelector:...]",
          __FILE__, __LINE__);
#endif
    
#if GREED_KEYDOWN == 0
    id delegate = [self delegate];
    
    if ([delegate respondsToSelector:aSelector]) {
        [delegate performSelector:aSelector withObject:nil];
    }
#endif
}

- (void)insertText:(id)aString
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView insertText:%@]",
          __FILE__, __LINE__, aString);
#endif
    
    if ([self hasMarkedText]) {
        IM_INPUT_MARKEDRANGE = NSMakeRange(0, 0);
        [markedText release];
		markedText=nil;
    }

    if ([(NSString*)aString length]>0) {
        if ([_delegate respondsToSelector:@selector(insertText:)])
            [_delegate insertText:aString];
        else
            [super insertText:aString];

        IM_INPUT_INSERT = YES;
    }

}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange
{
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView setMarkedText:%@ selectedRange:(%d,%d)]",
          __FILE__, __LINE__, aString, selRange.location, selRange.length);
#endif
	[markedText release];
    if ([aString isKindOfClass:[NSAttributedString class]]) {
        markedText=[[NSAttributedString alloc] initWithString:[aString string] attributes:[self markedTextAttributes]];
    }
    else {
        markedText=[[NSAttributedString alloc] initWithString:aString attributes:[self markedTextAttributes]];
    }
	IM_INPUT_MARKEDRANGE = NSMakeRange(0,[markedText length]);
    IM_INPUT_SELRANGE = selRange;
	[self setNeedsDisplay: YES];
}

- (void)unmarkText
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView unmarkText]", __FILE__, __LINE__ );
#endif
    IM_INPUT_MARKEDRANGE = NSMakeRange(0, 0);
}

- (BOOL)hasMarkedText
{
    BOOL result;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView hasMarkedText]", __FILE__, __LINE__ );
#endif
    if (IM_INPUT_MARKEDRANGE.length > 0)
        result = YES;
    else
        result = NO;
    
    return result;
}

- (NSRange)markedRange
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView markedRange]", __FILE__, __LINE__);
#endif
    
    //return IM_INPUT_MARKEDRANGE;
    if (IM_INPUT_MARKEDRANGE.length > 0) {
        return NSMakeRange([dataSource cursorX]-1, IM_INPUT_MARKEDRANGE.length);
    }
    else
        return NSMakeRange([dataSource cursorX]-1, 0);
}

- (NSRange)selectedRange
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView selectedRange]", __FILE__, __LINE__);
#endif
    return NSMakeRange(NSNotFound, 0);
}

- (NSArray *)validAttributesForMarkedText
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView validAttributesForMarkedText]", __FILE__, __LINE__);
#endif
    return [NSArray arrayWithObjects:NSForegroundColorAttributeName,
        NSBackgroundColorAttributeName,
        NSUnderlineStyleAttributeName,
		NSFontAttributeName,
        nil];
}

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView attributedSubstringFromRange:(%d,%d)]", __FILE__, __LINE__, theRange.location, theRange.length);
#endif
	
    return [markedText attributedSubstringFromRange:NSMakeRange(0,theRange.length)];
}

- (unsigned int)characterIndexForPoint:(NSPoint)thePoint
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView characterIndexForPoint:(%f,%f)]", __FILE__, __LINE__, thePoint.x, thePoint.y);
#endif
    
    return thePoint.x/charWidth;
}

- (long)conversationIdentifier
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView conversationIdentifier]", __FILE__, __LINE__);
#endif
    return (long)self; //not sure about this
}

- (NSRect)firstRectForCharacterRange:(NSRange)theRange
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView firstRectForCharacterRange:(%d,%d)]", __FILE__, __LINE__, theRange.location, theRange.length);
#endif
    int y=[dataSource cursorY]-1;
    int x=[dataSource cursorX]-1;
    
    NSRect rect=NSMakeRect(x*charWidth+MARGIN,(y+[dataSource numberOfLines] - [dataSource height]+1)*lineHeight,charWidth*theRange.length,lineHeight);
    //NSLog(@"(%f,%f)",rect.origin.x,rect.origin.y);
    rect.origin=[[self window] convertBaseToScreen:[self convertPoint:rect.origin toView:nil]];
    //NSLog(@"(%f,%f)",rect.origin.x,rect.origin.y);
    
    return rect;
}

- (void) findString: (NSString *) aString forwardDirection: (BOOL) direction ignoringCase: (BOOL) ignoreCase
{
	BOOL foundString;
	int tmpX, tmpY;
	
	foundString = [self _findString: aString forwardDirection: direction ignoringCase: ignoreCase];
	if(foundString == NO)
	{
		// start from beginning or end depending on search direction
		tmpX = lastFindX;
		tmpY = lastFindY;
		lastFindX = lastFindY = -1;
		foundString = [self _findString: aString forwardDirection: direction ignoringCase: ignoreCase];
		if(foundString == NO)
		{
			lastFindX = tmpX;
			lastFindY = tmpY;
		}
	}
	
}

// transparency
- (float) transparency
{
	return (transparency);
}

- (void) setTransparency: (float) fVal
{
	transparency = fVal;
	forceUpdate = YES;
	[self setNeedsDisplay: YES];
}

- (BOOL) useTransparency
{
  return useTransparency;
}

- (void) setUseTransparency: (BOOL) flag
{
  useTransparency = flag;
  forceUpdate = YES;
  [self setNeedsDisplay: YES];
}

// service stuff
- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
	//NSLog(@"%s: %@, %@", __PRETTY_FUNCTION__, sendType, returnType);
	
	if(sendType != nil && [sendType isEqualToString: NSStringPboardType])
		return (self);
	
	return ([super validRequestorForSendType: sendType returnType: returnType]);
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *copyString;
        
    copyString=[self selectedText];
    
    if (copyString && [copyString length]>0) {
        [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: self];
        [pboard setString: copyString forType: NSStringPboardType];
		return (YES);
    }
	
	return (NO);
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	return (NO);
}

@end

//
// private methods
//
@implementation PTYTextView (Private)

- (void) _renderChar:(NSImage *)image withChar:(unichar) carac withColor:(NSColor*)color withFont:(NSFont*)aFont bold:(int)bold
{
	NSAttributedString  *crap;
	NSDictionary *attrib;
	NSFont *theFont;
	float strokeWidth = 0;
	BOOL renderBold;
	
	//NSLog(@"%s: drawing char %c", __PRETTY_FUNCTION__, carac);
	//NSLog(@"%@",NSStrokeWidthAttributeName);
	
	theFont = aFont;
	renderBold = bold;
	if([self disableBold])
		renderBold = NO;
	
	// Check if there is native bold support
	if(renderBold)
	{
		theFont = [[NSFontManager sharedFontManager] convertFont: aFont toHaveTrait: NSBoldFontMask];
		
		// check if conversion was successful, else use our own methods to convert to bold
		if([[NSFontManager sharedFontManager] fontNamed: [theFont fontName] hasTraits: NSBoldFontMask] == YES)
		{
			strokeWidth = 0;
			renderBold = NO;
		}
		else
		{
			strokeWidth = antiAlias?(float)bold*(-0.1):0;
			theFont = aFont;
		}
	}
	
#ifndef GNUSTEP   
	if (systemVersion >= 0x00001030)
	{
		attrib=[NSDictionary dictionaryWithObjectsAndKeys:
			theFont, NSFontAttributeName,
			color, NSForegroundColorAttributeName,
			[NSNumber numberWithFloat: strokeWidth], @"NSStrokeWidth",
			nil];
	}
	else
#endif   
	{
		attrib=[NSDictionary dictionaryWithObjectsAndKeys:
			theFont, NSFontAttributeName,
			color, NSForegroundColorAttributeName,
			nil];		
	}
	
	
	crap = [[[NSAttributedString alloc]initWithString:[NSString stringWithCharacters:&carac length:1]
										   attributes:attrib] autorelease];
	[image lockFocus];
	[[NSGraphicsContext currentContext] setShouldAntialias: antiAlias];
	[crap drawAtPoint:NSMakePoint(0,0)];
#ifndef GNUSTEP   
	// on older systems, for bold, redraw the character offset by 1 pixel
	if (renderBold && (systemVersion < 0x00001030 || !antiAlias))
	{
		[crap drawAtPoint:NSMakePoint(1,0)];
	}
#endif
	[image unlockFocus];
} // renderChar

#define  CELLSIZE (CACHESIZE/256)
- (NSImage *) _getCharImage:(unichar) code color:(int)fg doubleWidth:(BOOL) dw
{
	int i;
	int j;
	NSImage *image;
	int width;
	unsigned int c = fg;
	int seed;
	
	if (fg & SELECTED_TEXT) {
		c = SELECT_CODE | (fg & BOLD_MASK);
	}
	else if (fg & CURSOR_TEXT) {
		c = CURSOR_CODE | (fg & BOLD_MASK);
	}
	else {
		c &= (BOLD_MASK|0x1f); // turn of all masks except for bold and default fg color
	}
	if (!code) return nil;
	width = dw?2:1;
	seed = code;
	seed <<= 8;
	srand( seed + c );
	i = rand() % (CACHESIZE-CELLSIZE);
	for(j = 0;(charImages[i].code!=code || charImages[i].color!=c) && charImages[i].image && j<CELLSIZE; i++, j++);
	if (!charImages[i].image) {
		//  NSLog(@"add into cache");
		image=charImages[i].image=[[NSImage alloc]initWithSize:NSMakeSize(charWidth*width, lineHeight)];
		charImages[i].code=code;
		charImages[i].color=c;
		charImages[i].count=1;
		[self _renderChar: image 
				withChar: code
			   withColor: [self colorForCode: c] 
				withFont: ISDOUBLEWIDTHCHARACTER(code)?nafont:font
					bold: c&BOLD_MASK];
		
		return image;
	}
	else if (j>=CELLSIZE) {
		// NSLog(@"new char, but cache full (%d, %d, %d)", code, c, i);
		int t=1;
		for(j=2; j<=CELLSIZE; j++) {	//find a least used one, and replace it with new char
			if (charImages[i-j].count < charImages[i-t].count) t = j;
		}
		t = i - t;
		[charImages[t].image release];
		image=charImages[t].image=[[NSImage alloc]initWithSize:NSMakeSize(charWidth*width, lineHeight)];
		charImages[t].code=code;
		charImages[t].color=c;
		for(j=1; j<=CELLSIZE; j++) {	//reset the cache count
			charImages[i-j].count -= charImages[t].count;
		}
		charImages[t].count=1;
		
		[self _renderChar: image 
				withChar: code
			   withColor: [self colorForCode: c] 
				withFont: ISDOUBLEWIDTHCHARACTER(code)?nafont:font
					bold: c & BOLD_MASK];
		return image;
	}
	else {
		//		NSLog(@"already in cache");
		charImages[i].count++;
		return charImages[i].image;
	}
	
}

- (void) _drawCharacter:(unichar)c fgColor:(int)fg AtX:(float)X Y:(float)Y doubleWidth:(BOOL) dw
{
	NSImage *image;
	
	if (c) {
		//NSLog(@"%s: %c(%d)",__PRETTY_FUNCTION__, c,c);
		image=[self _getCharImage:c 
						   color:fg
					 doubleWidth:dw];
		[image compositeToPoint:NSMakePoint(X,Y) operation:NSCompositeSourceOver];
	}
}	

- (void) _scrollToLine:(int)line
{
	NSRect aFrame;
	aFrame.origin.x = 0;
	aFrame.origin.y = line * lineHeight;
	aFrame.size.width = [self frame].size.width;
	aFrame.size.height = lineHeight;
	//forceUpdate = YES;
	[self scrollRectToVisible: aFrame];
}


- (void) _selectFromX:(int)startx Y:(int)starty toX:(int)endx Y:(int)endy
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTextView _selectFromX:%d Y:%d toX:%d Y:%d]", __FILE__, __LINE__, startx, starty, endx, endy);
#endif

	int bfHeight;
	int width, height, x, y, idx, startIdx, endIdx;
	char newbg;
	char *dirty;
	screen_char_t *theLine;
	
	width = [dataSource width];
	height = [dataSource numberOfLines];
	bfHeight = height - [dataSource height];
	if (startX == -1) startIdx = endIdx = width*height+1;
	else {
		startIdx = startx + starty * width;
		endIdx = endx + endy * width;
		if (startIdx > endIdx) {
			idx = startIdx;
			startIdx = endIdx;
			endIdx = idx;
		}
	}
	
	for (idx=y=0; y<height; y++) {
		theLine = [dataSource getLineAtIndex: y];
		
		if (y < bfHeight) 
		{
			dirty = NULL;
		} 
		else 
		{
			dirty = [dataSource dirty] + (y - bfHeight) * width;
		}
		for(x=0; x < width; x++, idx++) 
		{
			if (idx >= startIdx && idx<=endIdx) 
				newbg = theLine[x].bg_color | SELECTION_MASK;
			else
				newbg = theLine[x].bg_color & ~SELECTION_MASK;
			if (newbg != theLine[x].bg_color) 
			{
				theLine[x].bg_color = newbg;
				if (dirty) dirty[x] = 1;
			}
		}		
	}
}

- (NSString *) _getWordForX: (int) x 
					y: (int) y 
			   startX: (int *) startx 
			   startY: (int *) starty 
				 endX: (int *) endx 
				 endY: (int *) endy
{
	NSString *aString,*wordChars;
	int tmpX, tmpY, x1, y1, x2, y2;

	// grab our preference for extra characters to be included in a word
	wordChars = [[PreferencePanel sharedInstance] wordChars];
	if(wordChars == nil)
		wordChars = @"";		
	// find the beginning of the word
	tmpX = x;
	tmpY = y;
	while(tmpX >= 0)
	{
		aString = [self contentFromX:tmpX Y:tmpY ToX:tmpX Y:tmpY breakLines: NO pad: YES];
		if(([aString length] == 0 || 
			[aString rangeOfCharacterFromSet: [NSCharacterSet alphanumericCharacterSet]].length == 0) &&
		   [wordChars rangeOfString: aString].length == 0)
			break;
		tmpX--;
		if(tmpX < 0 && tmpY > 0)
		{
			tmpY--;
			tmpX = [dataSource width] - 1;
		}
	}
	if(tmpX != x)
		tmpX++;
	
	if(tmpX < 0)
		tmpX = 0;
	if(tmpY < 0)
		tmpY = 0;
	if(tmpX >= [dataSource width])
	{
		tmpX = 0;
		tmpY++;
	}
	if(tmpY >= [dataSource numberOfLines])
		tmpY = [dataSource numberOfLines] - 1;	
	if(startx)
		*startx = tmpX;
	if(starty)
		*starty = tmpY;
	x1 = tmpX;
	y1 = tmpY;
	
	
	// find the end of the word
	tmpX = x;
	tmpY = y;
	while(tmpX < [dataSource width])
	{
		aString = [self contentFromX:tmpX Y:tmpY ToX:tmpX Y:tmpY breakLines: NO pad: YES];
		if(([aString length] == 0 || 
			[aString rangeOfCharacterFromSet: [NSCharacterSet alphanumericCharacterSet]].length == 0) &&
		   [wordChars rangeOfString: aString].length == 0)
			break;
		tmpX++;
		if(tmpX >= [dataSource width] && tmpY < [dataSource numberOfLines])
		{
			tmpY++;
			tmpX = 0;
		}
	}
	if(tmpX != x)
		tmpX--;
	
	if(tmpX < 0)
	{
		tmpX = [dataSource width] - 1;
		tmpY--;
	}
	if(tmpY < 0)
		tmpY = 0;		
	if(tmpX >= [dataSource width])
		tmpX = [dataSource width] - 1;
	if(tmpY >= [dataSource numberOfLines])
		tmpY = [dataSource numberOfLines] - 1;
	if(endx)
		*endx = tmpX;
	if(endy)
		*endy = tmpY;
	
	x2 = tmpX;
	y2 = tmpY;

	return ([self contentFromX:x1 Y:y1 ToX:x2 Y:y2 breakLines: NO pad: YES]);
	
}

- (unsigned int) _checkForSupportedDragTypes:(id <NSDraggingInfo>) sender
{
    NSString *sourceType;
    BOOL iResult;
    
    iResult = NSDragOperationNone;
    
    // We support the FileName drag type for attching files
    sourceType = [[sender draggingPasteboard] availableTypeFromArray: [NSArray arrayWithObjects:
        NSFilenamesPboardType,
        NSStringPboardType,
        nil]];
    
    if (sourceType)
        iResult = NSDragOperationCopy;
    
    return iResult;
}

- (void) _savePanelDidEnd: (NSSavePanel *) theSavePanel
               returnCode: (int) theReturnCode
              contextInfo: (void *) theContextInfo
{
    // If successful, save file under designated name
    if (theReturnCode == NSOKButton)
    {
        if ( ![(NSData *)theContextInfo writeToFile: [theSavePanel filename] atomically: YES] )
            NSBeep();
    }
    // release our hold on the data
    [(NSData *)theContextInfo release];
}

- (BOOL) _isBlankLine: (int) y
{
	NSString *lineContents, *blankLine;
	char blankString[1024];	
	
	
	lineContents = [self contentFromX: 0 Y: y ToX: [dataSource width] - 1 Y: y breakLines: NO pad: YES];
	memset(blankString, ' ', 1024);
	blankString[[dataSource width]] = 0;
	blankLine = [NSString stringWithUTF8String: (const char*)blankString];
	
	return ([lineContents isEqualToString: blankLine]);
	
}

- (void) _openURL: (NSString *) aURLString
{
    NSURL *url;
    NSString* trimmedURLString;
	
    trimmedURLString = [aURLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// length returns an unsigned value, so couldn't this just be ==? [TRE]
    if([trimmedURLString length] <= 0)
        return;
	    
    // Check for common types of URLs
    if ([trimmedURLString hasPrefix:@"file://"])
        url = [NSURL URLWithString:trimmedURLString];
    else if ([trimmedURLString hasPrefix:@"ftp"])
    {
        if (![trimmedURLString hasPrefix:@"ftp://"])
            url = [NSURL URLWithString:[@"ftp://" stringByAppendingString:trimmedURLString]];
        else
            url = [NSURL URLWithString:trimmedURLString];
    }
	else if ([trimmedURLString hasPrefix:@"mailto:"])
        url = [NSURL URLWithString:trimmedURLString];
	else if([trimmedURLString rangeOfString: @"@"].location != NSNotFound)
		url = [NSURL URLWithString:[@"mailto:" stringByAppendingString:trimmedURLString]];
	else if ([trimmedURLString hasPrefix:@"https://"])
        url = [NSURL URLWithString:trimmedURLString];
    else if (![trimmedURLString hasPrefix:@"http"])
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:trimmedURLString]];
    else
        url = [NSURL URLWithString:trimmedURLString];
	
    [[NSWorkspace sharedWorkspace] openURL:url];
	
}

- (void) _clearCacheForColor:(int)colorIndex
{
	int i;

	for ( i = 0 ; i < CACHESIZE; i++) {
		if (charImages[i].color == colorIndex) {
			[charImages[i].image release];
			charImages[i].image = nil;
		}
	}
}

- (BOOL) _findString: (NSString *) aString forwardDirection: (BOOL) direction ignoringCase: (BOOL) ignoreCase
{
	int x1, y1, x2, y2;
	NSString *searchBody;
	NSRange foundRange;
	int anIndex;
	unsigned searchMask = 0;
	
	if([aString length] <= 0)
	{
		NSBeep();
		return (NO);
	}
	
	// check if we had a previous search result
	if(lastFindX > -1)
	{
		if(direction)
		{
			x1 = lastFindX + 1;
			y1 = lastFindY;
			if(x1 >= [dataSource width])
			{
				if(y1 < [dataSource numberOfLines] - 1)
				{
					// advance search beginning to next line
					x2 = 0;
					y1++;
				}
				else
				{
					// wrap around to beginning
					x1 = y1 = 0;
				}
			}
			x2 = [dataSource width] - 1;
			y2 = [dataSource numberOfLines] - 1;
		}
		else
		{
			x1 = y1 = 0;
			x2 = lastFindX - 1;
			y2 = lastFindY;
			if(x2 <= 0)
			{
				if(y2 > 0)
				{
					// stop search at end of previous line
					x2 = [dataSource width] - 1;
					y2--;
				}
				else
				{
					// wrap around to the end
					x2 = [dataSource width] - 1;
					y2 = [dataSource numberOfLines] - 1;
				}
			}
		}
	}
	else
	{
		// no previous search results, search from beginning
		x1 = y1 = 0;
		x2 = [dataSource width] - 1;
		y2 = [dataSource numberOfLines] - 1;
	}
	
	// ok, now get the search body
	searchBody = [self contentFromX: x1 Y: y1 ToX: x2 Y: y2 breakLines: NO pad: YES];
	
	if([searchBody length] <= 0)
	{
		NSBeep();
		return (NO);
	}
	
	// do the search
	if(ignoreCase)
		searchMask |= NSCaseInsensitiveSearch;
	if(!direction)
		searchMask |= NSBackwardsSearch;	
	foundRange = [searchBody rangeOfString: aString options: searchMask];
	if(foundRange.location != NSNotFound)
	{
		// convert index to coordinates
		// get index of start of search body
		if(y1 > 0)
		{
			anIndex = y1*[dataSource width] + x1;
		}
		else
		{
			anIndex = x1;
		}
				
		// calculate index of start of found range
		anIndex += foundRange.location;
		startX = lastFindX = anIndex % [dataSource width];
		startY = lastFindY = anIndex/[dataSource width];
		
		// end of found range
		anIndex += foundRange.length - 1;
		endX = anIndex % [dataSource width];
		endY = anIndex/[dataSource width];
		
		
		[self _selectFromX:startX Y:startY toX:endX Y:endY];
		[self setNeedsDisplay:YES];
		[self _scrollToLine:endY];
		
		return (YES);
	}
	
	return (NO);
}

- (void) _dragText: (NSString *) aString forEvent: (NSEvent *) theEvent
{
	NSImage *anImage;
	int length;
	NSString *tmpString;
	NSPasteboard *pboard;
	NSArray *pbtypes;
	NSSize imageSize;
    NSPoint dragPoint;
	NSSize dragOffset = NSMakeSize(0.0, 0.0);

	//NSLog(@"%s: %@", __PRETTY_FUNCTION__, aString);

	
	length = [aString length];
	if([aString length] > 15)
		length = 15;
	
	imageSize = NSMakeSize(charWidth*length, lineHeight);
	anImage = [[NSImage alloc] initWithSize: imageSize];
    [anImage lockFocus];
	if([aString length] > 15)
		tmpString = [NSString stringWithFormat: @"%@...", [aString substringWithRange: NSMakeRange(0, 12)]];
	else
		tmpString = [aString substringWithRange: NSMakeRange(0, length)];
		
    [tmpString drawInRect: NSMakeRect(0, 0, charWidth*length, lineHeight) withAttributes: nil];
    [anImage unlockFocus];
    [anImage autorelease];
	
	// get the pasteboard
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
    // Declare the types and put our tabViewItem on the pasteboard
    pbtypes = [NSArray arrayWithObjects: NSStringPboardType, nil];
    [pboard declareTypes: pbtypes owner: self];
    [pboard setString: aString forType: NSStringPboardType];
	
    // tell our app not switch windows (currently not working)
    [NSApp preventWindowOrdering];
	
	// drag from center of the image
    dragPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    dragPoint.x -= imageSize.width/2;
	
    // start the drag
    [self dragImage:anImage at: dragPoint offset:dragOffset
			  event: mouseDownEvent pasteboard:pboard source:self slideBack:YES];
		
}

- (BOOL) _mouseDownOnSelection: (NSEvent *) theEvent
{
	NSPoint locationInWindow, locationInView;
	int row, col;
	char theBackgroundAttribute;
	BOOL result;
	screen_char_t *theLine;
	
	locationInWindow = [theEvent locationInWindow];
	
	locationInView = [self convertPoint: locationInWindow fromView: nil];
	col = (locationInView.x - MARGIN)/charWidth;
	row = locationInView.y/lineHeight;
	
	theLine = [dataSource getLineAtScreenIndex: row];
	
	theBackgroundAttribute = theLine[col].bg_color;
	
	
	
	if(theBackgroundAttribute & SELECTION_MASK)
		result = YES;
	else
		result = NO;
		
	return (result);
	
}

@end

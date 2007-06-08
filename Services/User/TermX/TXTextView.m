/*
   Copyright (c) 2007 <zetawoof gmail>
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import "TXTextView.h"
#import "TXCursor.h"
#import "GNUstep.h"

#define WINDOW_PAD 0
#define ROW_PAD 1 /* Between lines */
#define LINE_PAD 2 /* Between lines */
#define MAX_LINES 500

#define DEFAULT_COLS 80
#define DEFAULT_ROWS 24

extern unsigned char default_colors[256][3];

static BOOL blockRedraw = NO;

#define FORCE_RANGE(min,val,max) MAX(min, MIN(val, max))

#define SET_DEFAULT(index, dflt) do { if(esc.optptr <= index) { \
								esc.opts[index] = dflt; } } while(0)

#define COALESC(c) do { coalesc[cptr++] = c; } while(0)

#define ESC1(c)       do { COALESC(0x1b); COALESC(c); } while(0)
#define ESC2(c,d)     do { COALESC(0x1b); COALESC(c); COALESC(d); } while(0)
#define ESC3(c,d,e)   do { COALESC(0x1b); COALESC(c); \
	COALESC(d); COALESC(e); } while(0)
#define ESC4(c,d,e,f) do { COALESC(0x1b); COALESC(c);  COALESC(d); \
	COALESC(e); COALESC(f); } while(0)
#define CONTROL(x) ((x) & 0x1f)

#define TILDE1(c)   ESC3('[', c,    shift ? (ctl ? '@' : '$') : (ctl ? '^' : '~'))
#define TILDE2(c,d) ESC4('[', c, d, shift ? (ctl ? '@' : '$') : (ctl ? '^' : '~'))

#define FKEY(nbase, kbase) \
		TILDE2('0' + (c-kbase+nbase) / 10, '0' + (c-kbase+nbase) % 10);

@implementation TXTextView

- (void) setWindowTitle
{
	NSString *title = [NSString stringWithFormat: @"%dx%d", cols, rows];
	[[self window] setTitle: title];
}

- (NSColor *) colorAtIndex: (unsigned int) index
{
	NSColor *color = ctab[index];
	if (color == nil)
	{
		color = [NSColor colorWithCalibratedRed: default_colors[index][0] 
		                                  green: default_colors[index][1] 
		                                   blue: default_colors[index][2] 
		                                  alpha: 1];
		ctab[index] = RETAIN(color);
	}
	return color;
}

- (void) setBackgroundColorIndex: (unsigned int) index
{
	NSColor *color = [self colorAtIndex: index];
	[self setBackgroundColor: color];
}

- (NSRect) cursorFrame
{
	// non-blinking cursor for GNUSTep 
	NSRect rt = NSZeroRect;
	NSRect visible = [[self enclosingScrollView] documentVisibleRect];
	rt.size = fontSize;
	rt.size.height += ROW_PAD;
	rt.origin = NSMakePoint(WINDOW_PAD+LINE_PAD+cursor->column*fontSize.width,
	                        WINDOW_PAD+NSMinY(visible)+cursor->row*(fontSize.height+ROW_PAD));
	return rt;
}

- (void) blinkAction: (id) sender
{
	if ([[self window] isKeyWindow])
	{
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		if (blinkState)
		{
			[cursor setTextColor: [self colorAtIndex: cursor->fg]];
		}
		else
		{
			[cursor setTextColor: [self colorAtIndex: cursor->bg]];
		}
		[self lockFocus];
		[cursor drawWithFrame: [self cursorFrame] inView: self];
		[self unlockFocus];
		[context flushGraphics];
		blinkState = !blinkState;
	}
}

/* We use special method for pasting because TXTextView is not editable,
   Regular -paste: will not activated in main menu.
   And we need to process paste string manually. */
- (void) pasteInTerminal: (id) sender
{
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSGeneralPboard];
	NSArray *types = [NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil];
	NSString *availableType = [pboard availableTypeFromArray: types];
	if (availableType != nil)
	{
		NSString *s = [pboard stringForType: availableType];	
		if ([s length] > 0)
		{
			[tty writeString: s];
		}
	}
}

- (BOOL) isFlipped
{
	return YES;
}

- (void) setFont: (NSFont *) f
{
	if (f == nil)
		return;
	[super setFont: f];

	NSFontManager *fm = [NSFontManager sharedFontManager];
	ASSIGN(boldFont, [fm convertFont: [self font] toHaveTrait: NSBoldFontMask]);
	if (boldFont == nil)
	{
		NSLog(@"Cannot get bold font, use system bold font instead");
		ASSIGN(boldFont, [fm convertFont: [NSFont boldSystemFontOfSize: 12] toHaveTrait: NSFixedPitchFontMask]);
	}

	fontSize = [[self font] maximumAdvancement];
	fontSize.height = [[self font] pointSize];

	[attributes setObject: [self font] forKey: NSFontAttributeName];
	NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];;
	[ps setMaximumLineHeight: fontSize.height+ROW_PAD];
	[ps setLineBreakMode: NSLineBreakByCharWrapping];
	[attributes setObject: ps forKey: NSParagraphStyleAttributeName];
	DESTROY(ps);
	[attributes setObject: [NSNumber numberWithInt: 0]
	               forKey: NSLigatureAttributeName];

	/* We adjust font width because it may be different from font size */
	fontSize.width = [@"W" sizeWithAttributes: attributes].width;

	[cursor setFont: [self font]];
}

- (void) keyDown: (NSEvent *) event
{
	NSString *chars = [event characters];
	unsigned int mods = [event modifierFlags];
	BOOL shift = !!(mods & NSShiftKeyMask);
	BOOL ctl   = !!(mods & NSControlKeyMask);
	//	BOOL opt   = !!(mods & NSAlternateKeyMask);
	//	BOOL cmd   = !!(mods & NSCommandKeyMask);
	
	char coalesc[64]; // XXX fixed size
	int cptr = 0;
	int i;
	
	for(i = 0; i < [chars length]; i++) 
	{
		unichar c = [chars characterAtIndex:i];
		switch(c) 
		{
			case '\b':
				if(ctl)
					COALESC(CONTROL('H'));
				else
					COALESC('\b');
				break;
				
			case NSDeleteFunctionKey:
				ESC3('[', '3', '~');
				break;
				
			case '\t':
				if(shift)
					ESC2('[', 'Z');
				else
					COALESC('\t');
				break;
				
			case NSUpArrowFunctionKey:
			case NSDownArrowFunctionKey:
			case NSRightArrowFunctionKey:
			case NSLeftArrowFunctionKey:
				ESC2(  (ctl && !shift) ? 'O' : '[',
							 ((ctl ||  shift) ? "abdc" : "ABDC")[c - 0xF700]);
				break;
				
			case NSFindFunctionKey:
				TILDE1('1');
				break;
			case NSInsertFunctionKey:
				TILDE1('2');
				break;
			case NSExecuteFunctionKey:
				TILDE1('3');
				break;
			case NSSelectFunctionKey:
				TILDE1('4');
				break;
			case NSPageUpFunctionKey:
				TILDE1('5');
				break;
			case NSPageDownFunctionKey:
				TILDE1('6');
				break;
			case NSHomeFunctionKey:
				TILDE1('7');
				break;
			case NSEndFunctionKey:
				TILDE1('8');
				break;
				
			case NSHelpFunctionKey:
				TILDE2('2', '8');
				break;
			case NSMenuFunctionKey:
				TILDE2('2', '9');
				break;
								
			case NSF1FunctionKey:
			case NSF2FunctionKey:
			case NSF3FunctionKey:
			case NSF4FunctionKey:
			case NSF5FunctionKey:
				FKEY(11, NSF1FunctionKey);
				break;
				
			case NSF6FunctionKey:
			case NSF7FunctionKey:
			case NSF8FunctionKey:
			case NSF9FunctionKey:
			case NSF10FunctionKey:
				FKEY(17, NSF6FunctionKey);
				break;
				
			case NSF11FunctionKey:
			case NSF12FunctionKey:
			case NSF13FunctionKey:
			case NSF14FunctionKey:
				FKEY(23, NSF11FunctionKey);
				break;
				
			case NSF15FunctionKey:
			case NSF16FunctionKey:
				FKEY(28, NSF15FunctionKey);
				break;
				
			case NSF17FunctionKey:
			case NSF18FunctionKey:
			case NSF19FunctionKey:
			case NSF20FunctionKey:
			case NSF21FunctionKey:
			case NSF22FunctionKey:
			case NSF23FunctionKey:
			case NSF24FunctionKey:
			case NSF25FunctionKey:
			case NSF26FunctionKey:
			case NSF27FunctionKey:
			case NSF28FunctionKey:
			case NSF29FunctionKey:
			case NSF30FunctionKey:
			case NSF31FunctionKey:
			case NSF32FunctionKey:
			case NSF33FunctionKey:
			case NSF34FunctionKey:
			case NSF35FunctionKey:
				FKEY(31, NSF17FunctionKey);
				break;
								
			default:
				if(c < 0x100)
					COALESC(c);
		}
	}
	if(cptr > 0)
		[tty writeData:[NSData dataWithBytesNoCopy:coalesc
											length:cptr
										freeWhenDone:NO]];
}

- (id) initWithFrame:(NSRect) frame
{
	int i;

	self = [super initWithFrame: frame];

	attributes = [[NSMutableDictionary alloc] init];

	textStorage = [self textStorage];
	layoutManager = [self layoutManager];
	textContainer = [self textContainer];
#ifdef GNUSTEP
	[textContainer setWidthTracksTextView: YES];
	[textContainer setHeightTracksTextView: YES];
#endif
    [textContainer setLineFragmentPadding: LINE_PAD];

	ASSIGN(cursor, AUTORELEASE([[TXCursor alloc] initTextCell: @" "]));
	[cursor setBezeled: NO];
	[cursor setBordered: NO];
	ASSIGN(save_cursor, cursor);
#ifndef GNUSTEP
#if 0
	ASSIGN(blinkTimer, [NSTimer scheduledTimerWithTimeInterval: 0.5
	                        target: self 
	                        selector: @selector(blinkAction:)
	                        userInfo: nil
	                        repeats: YES]);
#endif
#endif
	blinkState = NO;
	wrapnext = NO;
		
	esc.mode = ESC_NORMAL;
				
	mode_relative_origin = NO;
	mode_wrap = YES;
	mode_vt52 = NO;
		
	charsetmap[0] = 'B';
	charsetmap[1] = 'B';
	charsetmap[2] = 'B';
	charsetmap[3] = 'B';

	rows = DEFAULT_ROWS;
	cols = DEFAULT_COLS;
	lastFrame = NSZeroRect;

	scrollRows = [[NSMutableArray alloc] init];

	/* Make sure it is NULL'd */
	scrollbuf = NULL;
	scroll_rows_alloc = NULL;
	tabstops = NULL;

	for(i = 0; i < 256; i++)
	{
		ctab[i] = nil;
	}
	
	tty = [[TTY alloc] initWithColumns: cols rows: rows];
	[tty setDelegate:self];
	
	return self;
}

- (void) updateText
{
	NSString *string = [textStorage string];
	int linesToDelete = totalLines - MAX_LINES;
	NSRange deleteRange = NSMakeRange(0, 0);
	NSRange lineRange = NSMakeRange(0, 0);

	[textStorage beginEditing];

	while (linesToDelete > 0)
	{
		lineRange = [string lineRangeForRange: NSMakeRange(NSMaxRange(lineRange), 0)];
		linesToDelete--;
		totalLines--;
		cachedLength -= lineRange.length;
		deleteRange.length += lineRange.length;
	}
	[textStorage deleteCharactersInRange: deleteRange];

	/* Clean up */
	int r, c;
	deleteRange = NSMakeRange(cachedLength, 0);
	string = [textStorage string];
	for(r = 0; r < rows; r++)
	{
		if (scrollbuf[r].dirty == YES)
		{
			/* First dirty line */
			break;
		}
		deleteRange = [string lineRangeForRange: deleteRange];
		deleteRange = NSMakeRange(NSMaxRange(deleteRange), 0);
	}
	deleteRange.length = [textStorage length]-deleteRange.location;

	for(r = 0; r < rows; r++) 
	{
		if (scrollbuf[r].dirty == YES)
		{
			NSColor *fgColor = nil, *bgColor = nil;
			unsigned int cur_fg = 0;
			unsigned int cur_bg = 0;
			NSMutableAttributedString *as = nil;
			ASSIGN(as, AUTORELEASE([[NSMutableAttributedString alloc] init]));
			NSString *s = nil;
			NSRange fg_range = NSMakeRange(0, 1);
			NSRange bg_range = NSMakeRange(0, 1);
			NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSColor whiteColor], NSForegroundColorAttributeName, 
					[NSColor blackColor], NSBackgroundColorAttributeName, 
					nil];
			s = [[NSString alloc] initWithBytes: scrollbuf[r].chars
			                                length: cols
			       encoding: [NSString defaultCStringEncoding]];
			/* Default color */
			[as beginEditing];
			[as appendAttributedString: AUTORELEASE([[NSAttributedString alloc] initWithString: s attributes: attr])];
			DESTROY(s);
			for (c = 0; c < cols; c++)
			{
				if (fgColor == nil)
				{
					cur_fg = scrollbuf[r].fg[c];
					fgColor = [self colorAtIndex: cur_fg];
				}
				if (bgColor == nil)
				{
					cur_bg = scrollbuf[r].bg[c];
					bgColor = [self colorAtIndex: cur_bg];
				}
				if ((cur_fg != scrollbuf[r].fg[c]) || (c == cols-1))
				{
					fgColor = [self colorAtIndex: cur_fg];
					if (NSMaxRange(fg_range) > [as length])
					{
						fg_range.length = [as length]-fg_range.location;
					}
					[as addAttribute: NSForegroundColorAttributeName
					    value: fgColor
					    range: fg_range];
					cur_fg = scrollbuf[r].fg[c];
					fg_range.location = c;
					fg_range.length = 1;
				}
				else
				{
					fg_range.length++;
				}
				if ((cur_bg != scrollbuf[r].bg[c]) || (c = cols-1))
				{
					bgColor = [self colorAtIndex: cur_bg];
					if (NSMaxRange(bg_range) > [as length])
					{
						bg_range.length = [as length]-bg_range.location;
					}
					[as addAttribute: NSBackgroundColorAttributeName
					    value: bgColor
					    range: bg_range];
					cur_bg = scrollbuf[r].bg[c];
					bg_range.location = c;
					bg_range.length = 1;
				}
				else
				{
					bg_range.length++;
				}
			}
			[as addAttributes: attributes range: NSMakeRange(0, [as length])];
			[as endEditing];
			[scrollRows replaceObjectAtIndex: r withObject: as];
		}
	}

	/* Remove text after cached text */
	[textStorage deleteCharactersInRange: deleteRange];
	BOOL keepReplacing = NO;
	for (r = 0; r < rows; r++)
	{
		if ((scrollbuf[r].dirty == YES) || (keepReplacing == YES))
		{
			keepReplacing = YES;
			NSAttributedString *as = [scrollRows objectAtIndex: r];
			if ((id)as == [NSNull null])
			{
				NSLog(@"Internal Error (%@), row %d cannot be NULL", NSStringFromSelector(_cmd), r);
			}
			[textStorage appendAttributedString: [scrollRows objectAtIndex: r]];
			if (r < rows-1)
			{
				[textStorage  appendAttributedString: AUTORELEASE([[NSAttributedString alloc] initWithString: @"\n" attributes: attributes])];
			}
			scrollbuf[r].dirty = NO;
		}
	}

	[textStorage endEditing];

#ifdef GNUSTEP
	NSSize size = [textStorage size];
	size.width += 2*LINE_PAD;
	[self setFrameSize: size];
#endif
	[self scrollRangeToVisible: NSMakeRange([textStorage length]-1, [textStorage length])];
}

- (void) tty: (TTY *) sender gotInput: (NSData *) dat
{
	CREATE_AUTORELEASE_POOL(x);
	blockRedraw = YES;
	[self doChars:dat];
	[self updateText];
	blockRedraw = NO;
	DESTROY(x);
}

- (void) tty: (TTY *) sender closed: (id) ignored
{
	[[self window] setTitle:@"(closed)"];
}


- (BOOL) acceptsFirstResponder
{
	return YES;
}

- (void) awakeFromNib
{
	[self setFont: [NSFont userFixedPitchFontOfSize: 12]];
	[self resizeWindowForTerminal];
	[self resizeBuffer];
	[[self window] makeFirstResponder: self];
}

- (void) dealloc
{
	if (scrollbuf) 
	{
		free(scrollbuf);
		free(scroll_rows_alloc);
		free(tabstops);
	}

	int i;
	for(i = 0; i < 256; i++)
	{
		DESTROY(ctab[i]);
	}
	DESTROY(cursor);
	DESTROY(save_cursor);
	if (blinkTimer)
	{
		[blinkTimer invalidate];
		DESTROY(blinkTimer);
	}
	DESTROY(scrollRows);
	DESTROY(attributes);
	DESTROY(tty);
	[super dealloc];
}

- (void) resizeWindowForTerminal
{
	NSRect old_frame = [[self window] frame];
	NSRect new_cr = NSMakeRect(0, 0,
						 cols * fontSize.width + 2 * WINDOW_PAD + 2 * LINE_PAD,
						 rows * (fontSize.height+ROW_PAD) + 2 * WINDOW_PAD);
	
	NSRect new_frame;
	NSScrollView *scrollView = [self enclosingScrollView];
	if (scrollView)
	{
		new_frame.size = [NSScrollView frameSizeForContentSize: new_cr.size
	                  hasHorizontalScroller: [scrollView hasHorizontalScroller]
		              hasVerticalScroller: [scrollView hasVerticalScroller]
		              borderType: [scrollView borderType]];
	}
	else
	{
		new_frame = new_cr;
	}
#ifdef GNUSTEP
	new_frame.size.height += 30;
#else
	new_frame = [[self window] frameRectForContentRect: new_frame];
#endif
	
	new_frame.origin = old_frame.origin;
	new_frame.origin.y -= new_frame.size.height - old_frame.size.height;
	[[self window] setFrame:new_frame display:YES];
	[[self window] setResizeIncrements:NSMakeSize(fontSize.width, fontSize.height+ROW_PAD)];
}

/* Resize buffer to match window frame */
- (void) resizeBuffer
{
	int oldRows = rows, oldCols = cols;
	struct tv_row *old_scrollbuf = scrollbuf;
	char *old_ralloc = scroll_rows_alloc;
	char *old_tabstops = tabstops;

	NSScrollView *scrollView = [self enclosingScrollView];
	NSRect rect = [scrollView  bounds];
	rect.size = [NSScrollView contentSizeForFrameSize: rect.size
					hasHorizontalScroller: [scrollView hasHorizontalScroller]
					hasVerticalScroller: [scrollView hasVerticalScroller]
					borderType: [scrollView borderType]];

	rows = (rect.size.height - 2 * WINDOW_PAD) / (fontSize.height+ROW_PAD);
	cols = (rect.size.width  - 2 * WINDOW_PAD - 2 * LINE_PAD) / fontSize.width;
	int overlapCols = MIN(cols, oldCols);
	
#if 0
	NSLog(@"Resizing from %dx%d to %dx%d - %d columns overlap",
					oldCols, oldRows, cols, rows, overlapCols);
#endif
	
	scrollbuf = malloc(rows * sizeof(struct tv_row));
	if (scrollbuf == NULL)
	{
		NSLog(@"Internal error: cannot get scrollbuf");
	}
	bzero(scrollbuf, rows*sizeof(struct tv_row));
	scroll_rows_alloc = malloc(rows * cols * sizeof(char) * 4);
	if (scroll_rows_alloc == NULL)
	{
		NSLog(@"Internal error: cannot get scroll_rows_alloc");
	}
	bzero(scroll_rows_alloc, rows * cols * sizeof(char) * 4);
	[scrollRows removeAllObjects];

	int r;
	for (r = 0; r < rows; r++) 
	{
		[scrollRows addObject: [NSNull null]];
		scrollbuf[r].dirty  = YES; // better safe than sorry
		scrollbuf[r].attr = &scroll_rows_alloc[(r*4) * cols];
		scrollbuf[r].fg = &scroll_rows_alloc[((r*4)+1) * cols];
		scrollbuf[r].bg = &scroll_rows_alloc[((r*4)+2) * cols];
		scrollbuf[r].chars = &scroll_rows_alloc[((r*4)+3) * cols];

		int c;
		for(c = 0; c < cols; c++) 
		{
			scrollbuf[r].chars[c] = ' '; // XXX MODE?
		}

		if ((r < oldRows) && old_scrollbuf)
		{
			memcpy(scrollbuf[r].attr, old_scrollbuf[r].attr, overlapCols*sizeof(char));
			memcpy(scrollbuf[r].fg, old_scrollbuf[r].fg, overlapCols*sizeof(char));
			memcpy(scrollbuf[r].bg, old_scrollbuf[r].bg, overlapCols*sizeof(char));
			memcpy(scrollbuf[r].chars, old_scrollbuf[r].chars, overlapCols*sizeof(char));
		}
	}

	tabstops = malloc(cols * sizeof(char));
	if (tabstops == NULL)
	{
		NSLog(@"Internal error: cannot get tabstops");
	}
	bzero(tabstops, cols*sizeof(char));
	
	int i = 0;
	if (old_tabstops)
	{
		for(i = 0; i < overlapCols; i++)
			tabstops[i] = old_tabstops[i];
		for(i = overlapCols; i < cols; i++)
			tabstops[i] = (i % 8 == 0) ? 1 : 0;
	}
	else
	{
		for(i = 0; i < cols; i++)
			tabstops[i] = (i % 8 == 0) ? 1 : 0;
	}

	if (old_ralloc)
	{
		free(old_ralloc);
		old_ralloc = NULL;
	}
	if (old_scrollbuf)
	{
		free(old_scrollbuf);
		old_scrollbuf = NULL;
	}
	if (old_tabstops)
	{
		free(old_tabstops);
		old_tabstops = NULL;
	}
	
	if (cursor->row >= rows)
		cursor->row = rows - 1;
	if (cursor->column >= cols)
		cursor->column = cols - 1;
	[tty windowSizedWithRows: rows cols: cols];
	
	// I'm not sure how "correct" this is, but it's what rxvt does. *shrug*
	scroll_top = 0;
	scroll_btm = rows - 1;

	lastFrame = [self frame];
	[self setWindowTitle];
}

- (void) drawRect: (NSRect) rect
{
	if (blockRedraw == YES)
		return;
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	[super drawRect: rect];

	// non-blinking cursor for GNUSTep 
	[cursor drawWithFrame: [self cursorFrame] inView: self];
}

- (void) scrollRegionFromRow: (int) start toRow: (int) end byLines: (int) count
{
	int i;
	struct tv_row tmp, *moved;
	id row;
	assert(start < end);
	if(count > 0) 
	{ // scroll text up (normal scroll)
		while(count--) 
		{
			row = [scrollRows objectAtIndex: start];
			RETAIN(row);
			tmp = scrollbuf[start];
			int i;
			for(i = start; i < end; i++)
			{
				scrollbuf[i] = scrollbuf[i + 1];
				[scrollRows replaceObjectAtIndex: i withObject: [scrollRows objectAtIndex: i+1]];
			}
			scrollbuf[end] = tmp;
			[scrollRows replaceObjectAtIndex: end withObject: row];
			RELEASE(row);
			moved = &scrollbuf[end];
		}
	} 
	else 
	{ // scroll text down (reverse scroll)
		count = -count;
		while(count--) 
		{
			row = [scrollRows objectAtIndex: end];
			RETAIN(row);
			tmp = scrollbuf[end];
			for(i = end; i > start; i--)
			{
				scrollbuf[i] = scrollbuf[i - 1];
				[scrollRows replaceObjectAtIndex: i withObject: [scrollRows objectAtIndex: i-1]];
			}
			scrollbuf[start] = tmp;
			[scrollRows replaceObjectAtIndex: start withObject: row];
			RELEASE(row);
			moved = &scrollbuf[start];
#if 0
			moved->dirty = YES;
#endif
		}
	}

	moved->dirty = YES;
	for(i = 0; i < cols; i++)
	{
		moved->chars[i] = ' '; // XXX what should this really fill with?
	}
}

- (void) scrollDown
{
	if (cursor->row >= scroll_btm) 
	{ // XXX what if out of range?
		NSRange lineRange = [[textStorage string] lineRangeForRange: NSMakeRange(cachedLength, 0)];
		cachedLength += lineRange.length;
		NSAttributedString *as = AUTORELEASE([[NSAttributedString alloc] initWithString: @"\n" attributes: attributes]);
		[textStorage appendAttributedString: as];
		[self scrollRegionFromRow:scroll_top toRow:scroll_btm byLines:1];

		totalLines++;
	} 
	else 
	{
		cursor->row++;
	}
}

- (void) scrollUp
{
	if (cursor->row <= scroll_top) 
	{ // XXX what if out of range? 
		[self scrollRegionFromRow:scroll_top toRow:scroll_btm byLines:-1];
	} 
	else 
	{
		cursor->row--;
	}
}

- (void) gotoRow: (int) newRow col: (int) newCol
{
	cursor->column = FORCE_RANGE(0, newCol, cols - 1);
	cursor->row = FORCE_RANGE(scroll_top,
						 newRow + (mode_relative_origin ? scroll_top : 0),
							 scroll_btm);
	wrapnext = NO;
}

- (void) gotoRelativeRow: (int) newRow col: (int) newCol
{
	cursor->column = FORCE_RANGE(0, cursor->column + newCol, cols - 1);
	cursor->row = FORCE_RANGE(scroll_top,
				 cursor->row + newRow + (mode_relative_origin ?  scroll_top : 0),
							 scroll_btm);
	wrapnext = NO;
}

- (void) processNonPrinting: (unsigned char) ch
{
	switch(ch) 
	{
		case 0x05: // ENQ
			[tty writeString:@"\e[[?1;2c"];
			break;
			
		case 0x07: // BEL
			NSBeep(); // XXX throttling?
			break;
			
		case 0x08: // BS
			if(cursor->column == 0) 
			{
				if(cursor->row > 0) 
				{
					cursor->column = cols - 1;
					cursor->row--;
				}
			} 
			else if(!wrapnext) 
			{
				cursor->column--;
			}
			wrapnext = NO;
			break;
			
		case 0x09: // HT (\t)
			if(cursor->column < cols - 1) 
			{
				while(++(cursor->column) < cols - 1) 
				{
					if(tabstops[cursor->column]) break;
				}
			}
			break;
			
		case 0x0a: // NL (\n)
		case 0x0b: // VT
		case 0x0c: // FF
			[self scrollDown];
			cursor->column = 0;
			wrapnext = NO;
			break;
			
		case 0x0d: // CR (\r)
			wrapnext = NO;
			cursor->column = 0;
			break;
			
		case 0x0e: // SO
			cursor->charset = 1;
			break;
			
		case 0x0f: // SI
			cursor->charset = 0;
			break;
		
		default:
			NSLog(@"don't know what to do with control character 0x%02x", ch);
	}
}

- (void)doVT52:(unsigned char)ch
{
	int i, j;
	switch(ch) 
	{
		case 'A':
			[self gotoRelativeRow:-1 col:0];
			break;
		case 'B':
			[self gotoRelativeRow:+1 col:0];
			break;
		case 'C':
			[self gotoRelativeRow:0 col:+1];
			break;
		case 'D':
			[self gotoRelativeRow:0 col:-1];
			break;
		case 'H':
			[self gotoRow:0 col:0];
			break;
		case 'I':
			[self scrollUp];
			break;
		case 'J':
			for(i = cursor->column; i < cols; i++) 
			{
				scrollbuf[cursor->row].chars[i] = ' '; // XXX attributes
			}
			scrollbuf[cursor->row].dirty = YES;
			for(i = cursor->row + 1; i < rows; i++) 
			{
				for(j = 0; j < cols; j++) 
				{
					scrollbuf[i].chars[j] = ' '; // XXX attributes
				}
				scrollbuf[i].dirty = YES;
			}
			break;
		case 'K':
			for(i = cursor->column; i < cols; i++) 
			{
				scrollbuf[cursor->row].chars[i] = ' '; // XXX attributes
			}
			scrollbuf[cursor->row].dirty = YES;
			break;
		case 'Y':
			esc.mode = ESC_VT52_Y1;
			break;
		case 'Z':
			[tty writeString:@"\e/Z"];
			break;
		case '<':
			mode_vt52 = NO;
			break;
		case 'F':
		case 'G':
		case '=':
		case '>':
			NSLog(@"Unimplemented VT52 sequence ^[%c", ch);
			break;
		
		default:
			NSLog(@"Unknown/unimplemented VT52 sequence ^[%c", ch);
	}
}

- (void) doEscape: (unsigned char) ch
{
	switch(ch) 
	{
		case '#':
		case '(':
		case ')':
		case '*':
		case '+':
			esc.mode = ESC_ESCAPE_TWO;
			esc.arg = ch;
			break;
		
		case '6': // DEC Back Index
			if(cursor->column > 0)
			{
				cursor->column--;
			}
			else 
			{
				memmove(scrollbuf[cursor->row].attr + 1,
								scrollbuf[cursor->row].attr,
								cols - 1);
				memmove(scrollbuf[cursor->row].fg + 1,
								scrollbuf[cursor->row].fg,
								cols - 1);
				memmove(scrollbuf[cursor->row].bg + 1,
								scrollbuf[cursor->row].bg,
								cols - 1);
				memmove(scrollbuf[cursor->row].chars + 1,
								scrollbuf[cursor->row].chars,
								cols - 1);
				scrollbuf[cursor->row].chars[0] = ' ';
			}
			break;
		
		case '7':
			ASSIGN(save_cursor, cursor);
			break;
		
		case '8':
			ASSIGN(cursor, save_cursor);
			break;
			
		case '9':
			if(cursor->column < cols - 1)
			{
				cursor->column++;
			}
			else 
			{
                memmove(scrollbuf[cursor->row].attr,
                                scrollbuf[cursor->row].attr + 1,
                                cols - 1);
                memmove(scrollbuf[cursor->row].fg,
                                scrollbuf[cursor->row].fg + 1,
                                cols - 1);
                memmove(scrollbuf[cursor->row].bg,
                                scrollbuf[cursor->row].bg + 1,
                                cols - 1);
                memmove(scrollbuf[cursor->row].chars,
                                scrollbuf[cursor->row].chars + 1,
                                cols - 1);
                scrollbuf[cursor->row].chars[cols - 1] = ' ';
			}
			break;
		
		case '=':
		case '>': // privmode?
			NSLog(@"Unimplemented escape sequence ^[%c", ch);
			break;
		
		case '@':
			esc.mode = ESC_IGNORE;
			esc.arg = 1;
			break;
		
		case 'D': // index up
			[self scrollDown];
			break;

		case 'E': // NEL
			[self scrollDown];
			cursor->column = 0;
			break;
			
		case 'H': // CHARACTER TABULATION SET
			tabstops[cursor->column] = 1;
			break;

		case 'M': // REVERSE LINE FEED
			[self scrollUp];
			break;

		case 'P': // DEVICE CONTROL STRING
		case 'Z': // SINGLE CHARACTER INTRODUCER
			NSLog(@"Unimplemented escape sequence ^[%c", ch);
			break;
			
		case '[': // CONTROL SEQUENCE INTRODUCER
			esc.mode = ESC_CSI;
			esc.submode = 0;
			esc.priv = 0;
			break;
		
		case ']': // OPERATING SYSTEM COMMAND
		case 'c': // RESET TO INITIAL STATE
		case 'n': // LOCKING-SHIFT TWO
		case 'o': // LOCKING-SHIFT THREE
			NSLog(@"Unimplemented escape sequence ^[%c", ch);
			break;

		default:
			NSLog(@"Unknown escape sequence ^[%c", ch);
	}
}

- (void) doEscapeTwo: (unsigned char)ch
{
	int i, j;
	switch(esc.arg) 
	{
		case '#':
			if(ch == 8) 
			{
				for(i = 0; i < rows; i++) 
				{
					for(j = 0; j < cols; j++) 
					{
						scrollbuf[i].chars[j] = 'E'; // XXX attributes?
					}
					scrollbuf[i].dirty = YES;
				}
			}
			break;
		case '(':
			charsetmap[0] = ch;
			break;
		case ')':
			charsetmap[1] = ch;
			break;
		case '*':
			charsetmap[2] = ch;
			break;
		case '+':
			charsetmap[3] = ch;
			break;
		default:
			NSLog(@"Got into ESCAPE_TWO in the wrong state somehow.");
	}
}

- (void)doEscapeCSI:(unsigned char)ch
{
	int i, j;
	// If you don't understand the structure here... 
	// it's more or less a reentrant
	// parser; esc.submode is used to store state across invocations.
	switch(esc.submode) 
	{
		case 0:
			if(ch >= '<' && ch <= '?') 
			{
				esc.priv = ch;
				return;
			}
			// FALL THROUGH TO STATE 1...
			esc.optptr = 0;
			esc.opts[0] = -1;
			esc.submode = 1;
		case 1:
			if(isdigit(ch)) 
			{
				if(esc.opts[esc.optptr] < 0) 
				{
					esc.opts[esc.optptr] = ch - '0';
				} 
				else 
				{
					esc.opts[esc.optptr] = 10 * esc.opts[esc.optptr] + ch - '0';
				}
			} 
			else if(ch == ';') 
			{
				if(esc.optptr < MAX_ESC_OPTS)
					esc.opts[++esc.optptr] = -1;
			} 
			else if(ch == 0x1b) 
			{
				esc.mode = ESC_ESCAPE; // yes, this leaves CSI mode permanently
			} 
			else if(ch < 0x20) 
			{
				[self processNonPrinting:ch];
			}
			if(ch < 0x40)
				return; // do more digits (or whatever)
			
			if(esc.opts[esc.optptr] != -1)
				esc.optptr++;

			// The point of no return
			esc.mode = ESC_NORMAL;

			if(ch > 0x7F)
				return;
			
			if(esc.priv) 
			{
				switch(esc.priv) 
				{
					case '>':
						if(ch == 'c') 
						{ // secondary device attributes
							[tty writeString:[NSString stringWithFormat:@"\e[>%d;%-.8s;0c", 't', @"0"]];
						}
						break;
					case '?':
						if(ch == 'h' || ch == 'l' || ch == 'r' || ch == 's' || ch == 't') {
							int state = (ch != 'l');
							switch(esc.opts[0]) 
							{
								case 2: // VT52
									mode_vt52 = YES; // ignore h/l choice!
									break;
								case 3: // 80-132
									// XXX resize terminal!
									break;
								case 6: // origin mode
									mode_relative_origin = state;
									break;
								case 7: // wrap mode
									mode_wrap = state;
									break;
								default:
									NSLog(@"Unknown mode ^[[?%d%c", esc.opts[0], ch);
							}
						}
						break;
					default:
						NSLog(@"Unknown CSI introducer in ^[[%c...%c", esc.priv, ch);
				}
				return;
			}
			
			switch(ch) 
			{
				case 'A': // CURSOR UP
					SET_DEFAULT(0, 1);
					[self gotoRelativeRow:-esc.opts[0] col:0];
					break;

				case 'B': // CURSOR DOWN
					SET_DEFAULT(0, 1);
					[self gotoRelativeRow:+esc.opts[0] col:0];
					break;

				case 'C': // CURSOR RIGHT
					SET_DEFAULT(0, 1);
					[self gotoRelativeRow:0 col:+esc.opts[0]];
					break;
				
				case 'D': // CURSOR LEFT
					SET_DEFAULT(0, 1);
					[self gotoRelativeRow:0 col:-esc.opts[0]];
					break;
					
				case 'H': // CURSOR POSITION
					SET_DEFAULT(0, 1);
					SET_DEFAULT(1, 1);
					[self gotoRow:(esc.opts[0] - 1) col:(esc.opts[1] - 1)];
					break;
					
				case 'J': // ERASE IN PAGE
					SET_DEFAULT(0, 0);
					switch(esc.opts[0]) 
					{
						case 0: // cursor to end of screen
						{
							for(i = cursor->column; i < cols; i++) 
							{
								scrollbuf[cursor->row].chars[i] = ' '; // XXX attributes
							}
							scrollbuf[cursor->row].dirty = YES;
							for(i = cursor->row + 1; i < rows; i++) 
							{
								for(j = 0; j < cols; j++) 
								{
									scrollbuf[i].chars[j] = ' '; // XXX attributes
								}
								scrollbuf[i].dirty = YES;
							}
							break;
						}
						case 1: // start of screen to cursor
						{
							for(i = 0; i < cursor->row; i++) 
							{
								for(j = 0; j < cols; j++) 
								{
									scrollbuf[i].chars[j] = ' '; // XXX attributes
								}
								scrollbuf[i].dirty = YES;
							}
							for(i = 0; i <= cursor->column; i++) 
							{
								scrollbuf[cursor->row].chars[i] = ' '; // etc
							}
							scrollbuf[cursor->row].dirty = YES;
							break;
						}
						case 2: // whole screen
						{
							for(i = 0; i < rows; i++) 
							{
								for(j = 0; j < cols; j++) 
								{
									scrollbuf[i].chars[j] = ' '; // XXX attributes
								}
								scrollbuf[i].dirty = YES;
							}
							break;
						}
						default:
							NSLog(@"Don't know how to ^[[%dJ", esc.opts[0]);
					}
					break;

				case 'K': // ERASE IN LINE
					SET_DEFAULT(0, 0);
					wrapnext = NO;
					switch(esc.opts[0]) 
					{
						case 0: // cursor to end of line
						{
							for(i = cursor->column; i < cols; i++) 
							{
								scrollbuf[cursor->row].chars[i] = ' '; // XXX attributes
							}
							scrollbuf[cursor->row].dirty = YES;
							break;
						}
						case 1: // start of line to cursor
						{
							for(i = 0; i <= cursor->column; i++) 
							{
								scrollbuf[cursor->row].chars[i] = ' '; // etc
							}
							scrollbuf[cursor->row].dirty = YES;
							break;
						}
						case 2: // whole line
						{
							for(i = 0; i < cols; i++) 
							{
								scrollbuf[cursor->row].chars[i] = ' '; // etc
							}
							scrollbuf[cursor->row].dirty = YES;
							break;
						}
					}
					break;
				
				case 'c': // DEVICE ATTRIBUTES
					[tty writeString:@"\e[?1;2c"];
					break;
				
				case 'f': // CHARACTER AND LINE POSITION
					SET_DEFAULT(0, 1);
					SET_DEFAULT(1, 1);
					[self gotoRow:(esc.opts[0] - 1)
										col:(esc.opts[1] - 1)];
					break;
				
				case 'g': // TABULATION CLEAR
					SET_DEFAULT(0, 0);
					switch(esc.opts[0]) 
					{
						case 0:
							tabstops[cursor->column] = 0;
							break;
						case 3:
						case 5:
							bzero(tabstops, cols);
							break;
					}
					break;
				
				case 'm': // SELECT GRAPHIC RENDITION
					for(i = 0; i < esc.optptr; i++) 
					{
						int sgr = esc.opts[i];
						switch(sgr) 
						{
							case 0:
								cursor->fg = 7;
								cursor->bg = 0;
								cursor->attribute = 0;
								break;
							case 1:
								cursor->attribute |= ATTR_BOLD;
								break;
							case 4:
								cursor->attribute |= ATTR_ULINE;
								break;
							case 5:
								cursor->attribute |= ATTR_BLINK;
								break;
							case 7:
								cursor->attribute |= ATTR_RVID;
								break;
							case 22:
								cursor->attribute &= ~ATTR_BOLD;
								break;
							case 24:
								cursor->attribute &= ~ATTR_ULINE;
								break;
							case 25:
								cursor->attribute &= ~ATTR_BLINK;
								break;
							case 27:
								cursor->attribute &= ~ATTR_RVID;
								break;
							case 30 ... 37:
								cursor->fg = sgr - 30;
								break;
							case 38: // XTerm/rxvt 256-color mode
								if(i + 2 < esc.optptr && esc.opts[i + 1] == 5) 
								{
									cursor->fg = esc.opts[i + 2];
									i += 2;
								}
								break;
							case 39: // Default foreground
								cursor->bg = 7;
								break;
							case 40 ... 47:
								cursor->bg = sgr - 40;
								break;
							case 48: // XTerm/rxvt 256-color mode
								if(i + 2 < esc.optptr && esc.opts[i + 1] == 5) 
								{
									cursor->bg = esc.opts[i + 2];
									i += 2;
								}
								break;
							case 49: // Default background
								cursor->bg = 0;
								break;
//						case 90 ... 107: do brightcolor mode
							default:
								NSLog(@"Unknown SGR %d", esc.opts[i]);
						}
					}
					break;
				case 'r': // DECSTBM: set top and bottom margins
					if(esc.optptr == 0) 
					{
						scroll_top = 0;
						scroll_btm = rows - 1;
					} 
					else if(esc.optptr == 1) 
					{
						scroll_top = esc.opts[0] - 1;
						scroll_btm = rows - 1;
					} 
					else 
					{
						scroll_top = esc.opts[0] - 1;
						scroll_btm = esc.opts[1] - 1;
					}
					// Check for validity
					if(scroll_top >= scroll_btm) 
					{
						scroll_top = 0;
						scroll_btm = rows - 1;
					}
					break;
												
				default:
					NSLog(@"Unknown CSI ^[[...%c", ch);
			}
	}
}

- (void) doChars: (NSData *) buf
{
	const unsigned char *bufdat = [buf bytes];
	int i;

	for(i = 0; i < [buf length]; i++) 
	{
		unsigned char ch = bufdat[i];
		
		switch(esc.mode) 
		{
			case ESC_ESCAPE:
				esc.mode = ESC_NORMAL;
				if(mode_vt52)
					[self doVT52:ch];
				else
					[self doEscape:ch];
				continue;
			case ESC_ESCAPE_TWO:
				esc.mode = ESC_NORMAL;
				[self doEscapeTwo:ch];
				continue;
			case ESC_CSI:
				[self doEscapeCSI:ch];
				continue;
			case ESC_VT52_Y1:
				esc.mode = ESC_VT52_Y2;
				esc.arg = ch;
				continue;
			case ESC_VT52_Y2: // A hollow voice says, "Plugh".
				esc.mode = ESC_NORMAL;
				[self gotoRow: (esc.arg - 0x20)
				          col: (ch - 0x20)]; // XXX or is this off by one?
				continue;
			case ESC_IGNORE:
				if(--esc.arg == 0)
					esc.mode = ESC_NORMAL;
				continue;
			case ESC_NORMAL: break;
		}
		
		if(ch == 0x1b) 
		{
			esc.mode = ESC_ESCAPE;
		} 
		else if(ch < 0x20) 
		{
			[self processNonPrinting:ch];
		} 
		else if(ch != 0x7F) 
		{ // go ahead and print it
			if(wrapnext) {
				[self scrollDown];
				cursor->column = 0;
				wrapnext = NO;
			}
			
			/* Charset translations */
			switch(charsetmap[(int)(cursor->charset)]) 
			{
				case '0': // Line drawing
					if(ch >= 60 && ch < 0x7F) ch -= 0x60;
					break;
				case 'A': // British
					if(ch == 0x23) ch = 0xA3; // pound to sterling
					break;
				case '5': // Finnish
				case 'C': // Also Finnish
					switch(ch) 
					{
						case 0x5B: ch = 0xC4; break; // Aumlaut
						case 0x7B: ch = 0xE4; break; // aumlaut
						case 0x5C: ch = 0xD6; break; // Oumlaut
						case 0x7C: ch = 0xF6; break; // oumlaut
						case 0x5D: ch = 0xC5; break; // Aring
						case 0x7D: ch = 0xE5; break; // aring
						case 0x5E: ch = 0xDC; break; // Uumlaut
						case 0x7E: ch = 0xFC; break; // uumlaut
						case 0x60: ch = 0xE9; break; // eacute
					}
					break;
				case 'K': // German
					switch(ch) 
					{
						case 0x40: ch = 0xA7; break; // section
						case 0x5B: ch = 0xC4; break; // Aumlaut
						case 0x7B: ch = 0xE4; break; // aumlaut
						case 0x5C: ch = 0xD6; break; // Oumlaut
						case 0x7C: ch = 0xF6; break; // oumlaut
						case 0x5D: ch = 0xDC; break; // Uumlaut
						case 0x7D: ch = 0xFC; break; // uumlaut
						case 0x7E: ch = 0xDF; break; // Ssharp
					}
					break;
			}
												
			// XXX insert mode			
			scrollbuf[cursor->row].attr[cursor->column] = cursor->attribute;
			scrollbuf[cursor->row].fg[cursor->column] = cursor->fg;
			scrollbuf[cursor->row].bg[cursor->column] = cursor->bg;
			scrollbuf[cursor->row].chars[cursor->column] = ch;
			scrollbuf[cursor->row].dirty = YES;
			if(cursor->column < cols - 1)
				cursor->column++;
			else if(mode_wrap)
				wrapnext = YES;
		}
	}
}

@end

/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "TXCursor.h"

@implementation TXCursor

- (void) drawInteriorWithFrame: (NSRect) cellFrame 
                        inView: (NSView *) controlView
{
#if 0
	[super drawInteriorWithFrame: cellFrame inView: controlView];
#else
	[[self textColor] set];
	NSRect r = cellFrame;
	r.origin.y += r.size.height-3;
	r.size.height = 3;
	NSRectFill(r);
#endif
}

- (id) initTextCell: (NSString *) s
{
	self = [super initTextCell: s];
	row = 0;
	column = 0;
	[self setTextColor: [NSColor whiteColor]];
	[self setBackgroundColor: [NSColor blackColor]];
	fg = 7;
	bg = 0;
	attribute = 0;
	charset = 0;
	return self;
}

- (void) setRow: (unsigned int) r
{
	row = r;
}

- (void) setColumn: (unsigned int) c
{
	column = c;
}

- (unsigned int) row
{
	return row;
}

- (unsigned int) column
{
	return column;
}

- (void) setCharset: (char) cs
{
	charset = cs;
}

- (char) charset
{
	return charset;
}

@end


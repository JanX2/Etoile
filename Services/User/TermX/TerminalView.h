/*
   Copyright (c) 2007 <zetawoof gmail>
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import "TTY.h"
#import "TXCursor.h"

#define MAX_ESC_OPTS 16

// Use text system for drawing. Otherwise, use attributed string
//#define TEXT_SYSTEM 

struct tv_row {
	BOOL dirty;
	uint32_t *data;   // MSB-LSB: Attr BG FG char
};

struct esc_state {
	enum {
		ESC_NORMAL,
		ESC_ESCAPE,
		ESC_ESCAPE_TWO,
		ESC_CSI,
		ESC_VT52_Y1, ESC_VT52_Y2,
		ESC_IGNORE
	} mode;
	char arg, submode, priv;
	int opts[MAX_ESC_OPTS];
	int optptr;
};

#define ATTR_BOLD  0x01
#define ATTR_ULINE 0x02
#define ATTR_BLINK 0x04
#define ATTR_RVID  0x08

@interface TerminalView : NSView
{
	NSFont *font;
	NSFont *boldFont;
	NSSize fontSize;
	TTY *tty;
	NSMutableArray *scrollRows; // We cache NSAttributedString for drawing
	NSMutableDictionary *attributes;
#ifdef TEXT_SYSTEM
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;
#endif

	NSRect lastFrame;

	NSTimer *redrawTimer;
	int chars_since_draw;

	NSColor *ctab[256];

	int rows, cols;
	int scroll_top, scroll_btm;
	struct tv_row *scrollbuf;
	uint32_t *scroll_rows_alloc;
	char *tabstops;

	TXCursor *cursor, *save_cursor;
	NSTimer *blinkTimer;
	BOOL blinkState;

	char charsetmap[4];
	struct esc_state esc;
	BOOL wrapnext;
	
	BOOL mode_relative_origin, mode_wrap, mode_vt52;
}

- (void) resizeWindowForTerminal;
- (void) resizeBuffer;
- (void)tty:(TTY *)tty gotInput:(NSData *)dat;
- (void)tty:(TTY *)tty closed:(id)ignored;

- (void)doChars:(NSData *)buf;

- (NSFont *) font;
- (void) setFont: (NSFont *) font;

@end

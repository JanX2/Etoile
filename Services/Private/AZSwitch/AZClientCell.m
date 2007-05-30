/*
 *  AZSwitch - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZClientCell.h"
#import "AZClient.h"
#import <EtoileUI/NSImage+NiceScaling.h>

#define CELL_HEIGHT 30
#define PAD 3

@implementation AZClientCell

- (void) setClient: (AZClient *) c
{
	ASSIGN(client, c);

	/* Get title size */
	[self setStringValue: [c title]];
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString: [self stringValue]];
	[as addAttribute: NSFontAttributeName
	           value: [self font] 
	           range: NSMakeRange(0, [as length])];
	ASSIGN(title, as);
	RELEASE(as);
	textSize = [title size];

	ASSIGN(icon, [[client icon] scaledImageToFitSize: NSMakeSize(CELL_HEIGHT-PAD*2, CELL_HEIGHT-PAD*2)]);
}

- (AZClient *) client 
{
	return client;
}

/* Override */
- (NSSize) cellSize
{
	NSSize size = NSZeroSize;
	size.width = textSize.width+2*PAD;
	size.height = CELL_HEIGHT;
	return size;
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame 
                        inView: (NSView *) controlView
{
	BOOL flipped = [controlView isFlipped];
//  NSFrameRect(cellFrame);

	/* Draw background is selected (NSOnState) */
	if ([self state] == NSOnState)
	{
		//[[NSColor controlBackgroundColor] set];
		[[NSColor yellowColor] set];
		NSRectFill(cellFrame);
	}

	/* Draw Icon */
	NSPoint p;
	if (icon)
	{
		p.x = NSMinX(cellFrame)+PAD;
		p.y = NSMinY(cellFrame)+PAD;
		if (flipped == YES)
		{
			p.y += [icon size].height-PAD;
			[icon setFlipped: YES];
		}
		[icon compositeToPoint: p
		             operation: NSCompositeSourceOver];
	}

	/* Draw Text */
#if 0
	p = cellFrame.origin;
	/* Put text in the center */
	p.x = NSMinX(cellFrame)+(NSWidth(cellFrame)-textSize.width)/2;
#else
	p.x += [icon size].width+PAD;
#endif
	p.y = NSMinY(cellFrame)+(NSHeight(cellFrame)-textSize.height)/2;
	if (flipped == YES)
	{
		p.y = NSMaxY(cellFrame)-[title size].height-PAD;
	}
	[title drawAtPoint: p];
}

- (id) init
{
	self = [super init];
	[self setSelectable: YES];
	return self;
}

- (void) dealloc
{
	DESTROY(client);
	[super dealloc];
}

@end


/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETFixedLayout.h"
#import "ETGeometry.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"


@implementation ETFixedLayout

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_autoresizesItem = YES;
	return self;
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETFixedLayout *newLayout = [super copyWithZone: aZone layoutContext: ctxt];

	newLayout->_autoresizesItem = _autoresizesItem;

	return newLayout;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"pin.png"];
}

/** Always returns YES since items are positioned based on their persistent 
geometry. */
- (BOOL) isPositional
{
	return YES;
}

/** Always returns NO since items are positioned based on their persistent 
geometry and not computed by the receiver. */
- (BOOL) isComputedLayout
{
	return NO;
}

/** Loads the persistent geometry of every item that belong to the layout context. */
- (void) setUp
{
	[super setUp];
	/* Frame must be set to persistent frame before -resizeItems:toScale: is 
	   called by -renderWithLayoutItems:isNewContent:, otherwise the scaling 
	   is computed based on the frame computed by the last layout in use which 
	   may not be ETFreeLayout (when switching from another layout). */
	[self loadPersistentFramesForItems: [[self layoutContext] items]];
}

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[super renderWithItems: items isNewContent: isNewContent];
	[[self layoutContext] setVisibleItems: items];
}

- (void) resizeItems: (NSArray *)items
    forNewLayoutSize: (NSSize)newLayoutSize
             oldSize: (NSSize)oldLayoutSize
{
	//NSLog(@"Resize items for new layout size %@ old size %@",
	//	NSStringFromSize(newLayoutSize), NSStringFromSize(oldLayoutSize));

	/* For a collapsed ETTitleBarItem, the decorated item content bounds is set zero */
	BOOL collapsing = NSEqualSizes(NSZeroSize, newLayoutSize);
	BOOL expanding = NSEqualSizes(NSZeroSize, oldLayoutSize);
	
	if (collapsing || expanding)
		return;
	
	NSParameterAssert(NSEqualSizes(ETNullSize, oldLayoutSize) == NO);
	NSParameterAssert(NSEqualSizes(NSZeroSize, newLayoutSize) == NO && NSEqualSizes(NSZeroSize, oldLayoutSize) == NO);

	if (NSEqualSizes(newLayoutSize, oldLayoutSize))
		return;

	if ([self autoresizesItems] == NO)
		return;

	for (ETLayoutItem *item in items)
	{
		[self resizeItem: item forNewLayoutSize: newLayoutSize oldSize: oldLayoutSize];
	}
}

- (void) resizeItem: (ETLayoutItem *)anItem
   forNewLayoutSize: (NSSize)newLayoutSize
            oldSize: (NSSize)oldLayoutSize
{
	ETAutoresizing autoresizing = [anItem autoresizingMask];

	if (autoresizing == ETAutoresizingNone)
		return;

	NSRect frame = [anItem frame];

	ETAutoresize(&frame.origin.x, &frame.size.width,
	             (autoresizing & ETAutoresizingFlexibleLeftMargin),
	             (autoresizing & ETAutoresizingFlexibleWidth),
	             (autoresizing & ETAutoresizingFlexibleRightMargin),
				 newLayoutSize.width, oldLayoutSize.width);
		
	BOOL flipped = ([[self layoutContext] isFlipped]);
	ETAutoresizing minMarginAutoresizing =
		(flipped ? ETAutoresizingFlexibleTopMargin : ETAutoresizingFlexibleBottomMargin);
	ETAutoresizing maxMarginAutoresizing =
		(flipped ? ETAutoresizingFlexibleBottomMargin : ETAutoresizingFlexibleTopMargin);

	ETAutoresize(&frame.origin.y, &frame.size.height,
	             (autoresizing & minMarginAutoresizing),
	             (autoresizing & ETAutoresizingFlexibleHeight),
	             (autoresizing & maxMarginAutoresizing),
				 newLayoutSize.height, oldLayoutSize.height);
	
	NSRect roundedFrame = NSIntegralRect(frame);

	[anItem setFrame: roundedFrame];
	/* For a non-recursive update, the resize must trigger a layout update.
	   Layout updates are bracketed inside +disableAutolayout and
	   +enableAutolayout. As a result, -setNeedsLayoutUpdate is disabled. */
	[[ETLayoutExecutor sharedInstance] addItem: (id)anItem];
}

- (BOOL) autoresizesItems
{
	return _autoresizesItem;
}

- (void) setAutoresizesItems: (BOOL)autoresize
{
	_autoresizesItem = autoresize;
}

/** Synchronizes the frames of every layout items provided by the layout 
context, with their persistent frame values.

When an item has no persistent frame value, the sync is done the other way 
around: the persistent frame is initialized with the frame value. */
- (void) loadPersistentFramesForItems: (NSArray *)items
{
	FOREACH(items, item, ETLayoutItem *)
	{
		/* First time persistent frame is accessed, initialize it */
		if (ETIsNullRect([item persistentFrame]))
		{
			[item setPersistentFrame: [item frame]];
		}
		else
		{
			[item setFrame: [item persistentFrame]];
		}
	}
}

@end

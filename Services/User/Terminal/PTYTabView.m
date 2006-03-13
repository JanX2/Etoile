/*
 **  PTYTabView.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Setlur
 **
 **  Project: iTerm
 **
 **  Description: NSTabView subclass. Implements drag and drop.
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

#import <iTerm/PTYTabView.h>
#import <iTerm/PTYTabViewItem.h>

#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0

@implementation PTYTabView

// Class methods that Apple should have provided
+ (NSSize) contentSizeForFrameSize: (NSSize) frameSize tabViewType: (NSTabViewType) type controlSize: (NSControlSize) controlSize
{
    NSRect aRect, contentRect;
    NSTabView *aTabView;
    float widthOffset, heightOffset;

#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -contentSizeForFrameSize");
#endif    

    // make a temporary tabview 
    aRect = NSMakeRect(0, 0, 200, 200);
    aTabView = [[NSTabView alloc] initWithFrame: aRect];
    [aTabView setTabViewType: type];
    [aTabView setControlSize: controlSize];

    // grab its content size
    contentRect = [aTabView contentRect];

    // calculate the offsets between total frame and content frame
    widthOffset = aRect.size.width - contentRect.size.width;
    heightOffset = aRect.size.height - contentRect.size.height;
    //NSLog(@"widthOffset = %f; heightOffset = %f", widthOffset, heightOffset);

    // release the temporary tabview
    [aTabView release];

    // Apply the offset to the given frame size
    return (NSMakeSize(frameSize.width - widthOffset, frameSize.height - heightOffset));
}

+ (NSSize) frameSizeForContentSize: (NSSize) contentSize tabViewType: (NSTabViewType) type controlSize: (NSControlSize) controlSize
{
    NSRect aRect, contentRect;
    NSTabView *aTabView;
    float widthOffset, heightOffset;

#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -frameSizeForContentSize");
#endif

    // make a temporary tabview
    aRect = NSMakeRect(0, 0, 200, 200);
    aTabView = [[NSTabView alloc] initWithFrame: aRect];
    [aTabView setTabViewType: type];
    [aTabView setControlSize: controlSize];

    // grab its content size
    contentRect = [aTabView contentRect];

    // calculate the offsets between total frame and content frame
    widthOffset = aRect.size.width - contentRect.size.width;
    heightOffset = aRect.size.height - contentRect.size.height;
    //NSLog(@"widthOffset = %f; heightOffset = %f", widthOffset, heightOffset);

    // release the temporary tabview
    [aTabView release];

    // Apply the offset to the given content size
    return (NSMakeSize(contentSize.width + widthOffset, contentSize.height + heightOffset));
}


- (id)initWithFrame: (NSRect) aRect
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif

    self = [super initWithFrame: aRect];

    // register for dragged types
    NSArray *typeArray = [NSArray arrayWithObjects: @"NSTabViewItemPboardType", nil];
    [self registerForDraggedTypes: typeArray];
    dragSessionInProgress = NO;
    dragTargetTabViewItemIndex = -1;
    
    return self;
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif

    if(mouseEvent != nil)
    {
	[mouseEvent release];
	mouseEvent = nil;
    }    
        
    [super dealloc];
}

// we don't want this to be the first responder in the chain
- (BOOL)acceptsFirstResponder
{
    return (NO);
}

- (void) drawRect: (NSRect) rect
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"iTermTabViewWillRedraw" object: self];
	[super drawRect: rect];
	
}

// build a conextual menu displaying the current tabs
- (NSMenu *) menuForEvent: (NSEvent *) theEvent
{
    int i;
    NSMenuItem *aMenuItem, *anotherMenuItem;
    NSMenu *cMenu, *aMenu;

    // Create a menu with a submenu to navigate between tabs
    cMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    anotherMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Select",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:nil keyEquivalent:@""];
    [cMenu addItem: anotherMenuItem];
    [anotherMenuItem release];

    aMenu = [[NSMenu alloc] initWithTitle:@""];
    
    for (i = 0; i < [self numberOfTabViewItems]; i++)
    {
        aMenuItem = [[NSMenuItem alloc] initWithTitle:[[self tabViewItemAtIndex: i] label]
                            action:@selector(selectTab:) keyEquivalent:@""];
        [aMenuItem setRepresentedObject: [[self tabViewItemAtIndex: i] identifier]];
        [aMenu addItem: aMenuItem];
        [aMenuItem release];
    }
    [anotherMenuItem setSubmenu: aMenu];
    [aMenu release];
    
    // Ask our delegate if it has anything to add
    id delegate = [self delegate];
    if([delegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[delegate tabViewContextualMenu: theEvent menu: cMenu];

    return (cMenu);
}

// selects a tab from the contextual menu
- (void) selectTab: (id) sender
{
    [self selectTabViewItemWithIdentifier: [sender representedObject]];
}

// NSTabView methods overridden
- (void) addTabViewItem: (NSTabViewItem *) aTabViewItem
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -addTabViewItem");
#endif

    // Let our delegate know
    id delegate = [self delegate];
    if([delegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[delegate tabView: self willAddTabViewItem: aTabViewItem];
    
    // add the item
    maxLabelSize=(([self tabViewType]==NSLeftTabsBezelBorder||[self tabViewType]==NSRightTabsBezelBorder)?[self frame].size.height-20:[self frame].size.width-20)/([self numberOfTabViewItems]+1)-17;
    if (maxLabelSize<20) 
        maxLabelSize=20;
    
    [super addTabViewItem: aTabViewItem];
}

- (void) removeTabViewItem: (NSTabViewItem *) aTabViewItem
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -removeTabViewItem");
#endif

    // Let our delegate know
    id delegate = [self delegate];
    if([delegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[delegate tabView: self willRemoveTabViewItem: aTabViewItem];
    
    // remove the item
    maxLabelSize=(([self tabViewType]==NSLeftTabsBezelBorder||[self tabViewType]==NSRightTabsBezelBorder)?[self frame].size.height-20:[self frame].size.width-20)/([self numberOfTabViewItems]-1)-17;
    if (maxLabelSize<20) 
        maxLabelSize=20;
    
    [super removeTabViewItem: aTabViewItem];
}

- (void) insertTabViewItem: (NSTabViewItem *) tabViewItem atIndex: (int) index
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -insertTabViewItem atIndex: %d", index);
#endif

    // Let our delegate know
    id delegate = [self delegate];
    if([delegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[delegate tabView: self willInsertTabViewItem: tabViewItem atIndex: index];    

    // insert the item
    maxLabelSize=(([self tabViewType]==NSLeftTabsBezelBorder||[self tabViewType]==NSRightTabsBezelBorder)?[self frame].size.height-20:[self frame].size.width-20)/([self numberOfTabViewItems]+1)-17;
    if (maxLabelSize<20) 
        maxLabelSize=20;
    
    [super insertTabViewItem: tabViewItem atIndex: index];

}

// drag and drop
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -draggingSourceOperationMaskForLocal: %d", flag);
#endif

    if([self numberOfTabViewItems] < 2)
	return (NSDragOperationNone);
    
    return (NSDragOperationMove);
}


- (void) mouseDown: (NSEvent *)theEvent
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -mouseDown");
#endif

    if(mouseEvent != nil)
    {
	[mouseEvent release];
	mouseEvent = nil;
    }

    [theEvent retain];
    mouseEvent = theEvent;

    //[super mouseDown: theEvent];
    
}

- (void) mouseUp: (NSEvent *)theEvent
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -mouseUp");
#endif

    NSPoint windowPoint;

    windowPoint = [theEvent locationInWindow];

    //[super mouseUp: theEvent];

    // If this is the same point as the mouseDown location, do a mouse click
    if ((windowPoint.x == [mouseEvent locationInWindow].x) &&
	(windowPoint.y == [mouseEvent locationInWindow].y))
    {
	NSTabViewItem *aTabViewItem;
	NSPoint localPoint;

	localPoint = [self convertPoint: windowPoint fromView: nil];
	aTabViewItem = [self tabViewItemAtPoint: localPoint];
	if(aTabViewItem != nil)
	    [self selectTabViewItem: aTabViewItem];
    }

    if(mouseEvent != nil)
    {
	[mouseEvent release];
	mouseEvent = nil;
    }

    dragSessionInProgress = NO;
}

- (void) mouseDragged: (NSEvent *)theEvent
{
    NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard;
    NSImage *anImage;
    NSSize imageSize;
    NSTabViewItem *aTabViewItem;
    NSPoint windowPoint, localPoint, dragPoint;

#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -mouseDragged");
#endif

    // Dragging done only if number of items is 2 or more
    if([self numberOfTabViewItems] < 2)
    {
	[super mouseDragged: theEvent];
	return;
    }

    // Drag only if we have moved the mouse about 8 pixels
    float x1, y1, x2, y2, dx, dy;
    x1 = [mouseEvent locationInWindow].x;
    y1 = [mouseEvent locationInWindow].y;
    x2 = [theEvent locationInWindow].x;
    y2 = [theEvent locationInWindow].y;
    dx = x1 - x2;
    dy = y1 - y2;
    if((dx*dx + dy*dy) < 64)
    {
	[super mouseDragged: theEvent];
	return;
    }


    // get the tabViewItem we want to drag
    windowPoint = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
    localPoint = [self convertPoint: windowPoint fromView: nil];
    aTabViewItem = [self tabViewItemAtPoint: localPoint];
    if(aTabViewItem == nil)
	return;    

    // make an image of tabViewItem's label that gets dragged
    imageSize = [[aTabViewItem label] sizeWithAttributes: nil];
    anImage = [[NSImage alloc] initWithSize: imageSize];
    [anImage lockFocus];
    [[aTabViewItem label] drawInRect: NSMakeRect(0, 0, imageSize.width, imageSize.height) withAttributes: nil];
    [anImage unlockFocus];
    [anImage autorelease];

    // drag from center of the image
    dragPoint = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    dragPoint.x -= imageSize.width/2;
    dragPoint.y += imageSize.height/2;

    // get the pasteboard
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];

    // Declare the types and put our tabViewItem on the pasteboard
    NSArray *pbtypes = [NSArray arrayWithObjects: @"NSTabViewItemPboardType", nil];
    [pboard declareTypes: pbtypes owner: self];
    int indexOfTabViewItem = [self indexOfTabViewItem: aTabViewItem];
    NSData *draggingData = [NSData dataWithBytes: &indexOfTabViewItem length: sizeof(indexOfTabViewItem)];
    [pboard setData: draggingData forType: @"NSTabViewItemPboardType"];

    // tell our app not switch windows (currently not working)
    [NSApp preventWindowOrdering];

    // start the drag
    [self dragImage:anImage at: dragPoint offset:dragOffset
			    event:mouseEvent pasteboard:pboard source:self slideBack:YES];
}


- (BOOL) shouldDelayWindowOrderingForEvent: (NSEvent *) theEvent
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -shouldDelayWindowOrderingForEvent");
#endif

    return (YES);
    
}

// NSDraggingDestination protocol
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -draggingEntered");
#endif
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    unsigned int mask = [sender draggingSourceOperationMask];
    unsigned int ret = (NSDragOperationMove & mask);

    if([[pboard types] indexOfObject: @"NSTabViewItemPboardType"] == NSNotFound)
    {
	NSLog(@"PTYTabView: draggingEntered: NSTabViewItemPboardType not found!");
	ret = NSDragOperationNone;
    }

    if(ret != NSDragOperationNone)
    {
	dragSessionInProgress = YES;
	[self setNeedsDisplay: YES];
    }

    return (ret);
    
}

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -draggingEntered");
#endif

    if(dragTargetTabViewItemIndex >= 0)
    {
	// Tell the previous drag target that it is not a target anymore
	[(PTYTabViewItem *)[self tabViewItemAtIndex: dragTargetTabViewItemIndex] resignDragTarget];
    }

    dragTargetTabViewItemIndex = -1;
    
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -draggingUpdated");
#endif

    NSPasteboard *pboard = [sender draggingPasteboard];
    unsigned int mask = [sender draggingSourceOperationMask];
    unsigned int ret = (NSDragOperationMove & mask);

    if([[pboard types] indexOfObject: @"NSTabViewItemPboardType"] == NSNotFound)
    {
	NSLog(@"PTYTabView: draggingEntered: NSTabViewItemPboardType not found!");
	ret = NSDragOperationNone;
    }

    if(ret != NSDragOperationNone)
    {
	dragSessionInProgress = YES;
	[self setNeedsDisplay: YES];
    }

    // if we are over another tabViewItem, give some visual feedback
    int aTabViewItemIndex;
    PTYTabView *aTabView;
    PTYTabViewItem *aTabViewItem, *dragTargetTabViewItem;
    NSData *pasteboardData;

    pasteboardData = [pboard dataForType: @"NSTabViewItemPboardType"];
    if(pasteboardData == nil)
    {
	NSLog(@"PTYTabView: draggingUpdated: no data on pasteboard!");
	return (NSDragOperationNone);
    }
    memcpy(&aTabViewItemIndex, [pasteboardData bytes], sizeof(aTabViewItemIndex));    

    aTabView = (PTYTabView *)[sender draggingSource];
    if(aTabView == nil)
	return (NSDragOperationNone);

    aTabViewItem = (PTYTabViewItem *)[aTabView tabViewItemAtIndex: aTabViewItemIndex];
    if(aTabViewItem == nil)
	return (NSDragOperationNone);
    
    NSPoint dropPoint = [sender draggingLocation];
    NSPoint localPoint = [self convertPoint: dropPoint fromView: nil];
    dragTargetTabViewItem = (PTYTabViewItem *)[self tabViewItemAtPoint: localPoint];
    
    if ((dragTargetTabViewItem == nil))
    {
	if(dragTargetTabViewItemIndex >= 0)
	{
	    // Tell the previous drag target that it is not a target anymore
	    [(PTYTabViewItem *)[self tabViewItemAtIndex: dragTargetTabViewItemIndex] resignDragTarget];
	}
	dragTargetTabViewItemIndex = -1;
    }
    else if (dragTargetTabViewItem == aTabViewItem)
    {
	if(dragTargetTabViewItemIndex >= 0)
	{
	    // Tell the previous drag target that it is not a target anymore
	    [(PTYTabViewItem *)[self tabViewItemAtIndex: dragTargetTabViewItemIndex] resignDragTarget];
	}

	dragTargetTabViewItemIndex = aTabViewItemIndex;
	ret = NSDragOperationNone;
	
    }
    else if((dragTargetTabViewItemIndex >= 0) &&
	    (dragTargetTabViewItem == (PTYTabViewItem *)[self tabViewItemAtIndex: dragTargetTabViewItemIndex]))
    {
	return (ret);
    }
    else 
    {
	if(dragTargetTabViewItemIndex >= 0)
	{
	    // Tell the previous drag target that it is not a target anymore
	    [(PTYTabViewItem *)[self tabViewItemAtIndex: dragTargetTabViewItemIndex] resignDragTarget];
	}
	
	dragTargetTabViewItemIndex = [self indexOfTabViewItem: dragTargetTabViewItem];
	// Tell the tabViewItem that it is a dragTarget
	[dragTargetTabViewItem becomeDragTarget];	
    }
    

    return (ret);
    
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -prepareForDragOperation");
#endif
    
    if (![[sender draggingSource] isKindOfClass: [PTYTabView class]])
    {
	NSLog(@"PTYTabView: prepareForDragOperation: unknown sender class %@", [[sender draggingSource] className]);
	return (NO);
    }

    NSPasteboard *pboard = [sender draggingPasteboard];

    // Make sure the pasteboard has a data type we know
    if([[pboard types] indexOfObject: @"NSTabViewItemPboardType"] == NSNotFound)
    {
	NSLog(@"PTYTabView: prepareForDragOperation: NSTabViewItemPboardType not found!");
	return (NO);
    }
    
    return (YES);
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"PTYTabView: -performDragOperation");
#endif

    if (![[sender draggingSource] isKindOfClass: [PTYTabView class]])
    {
	NSLog(@"PTYTabView: performDragOperation: unknown sender class %@", [[sender draggingSource] className]);
	return (NO);
    }

    NSPasteboard *pboard = [sender draggingPasteboard];

    // Make sure the pasteboard has a data type we know
    if([[pboard types] indexOfObject: @"NSTabViewItemPboardType"] == NSNotFound)
    {
	NSLog(@"PTYTabView: performDragOperation: NSTabViewItemPboardType not found!");
	return (NO);
    }

    // OK, do the drag
    int aTabViewItemIndex;
    PTYTabView *aTabView;
    NSTabViewItem *aTabViewItem;
    NSData *pasteboardData;
    int index = -1;
    NSPoint dropPoint, localPoint;
    id sourceDelegate, targetDelegate;

    // get the tabViewItem we are dragging
    pasteboardData = [pboard dataForType: @"NSTabViewItemPboardType"];
    if(pasteboardData == nil)
    {
	NSLog(@"PTYTabView: performDragOperation: no data on pasteboard!");
	return (NO);
    }
    memcpy(&aTabViewItemIndex, [pasteboardData bytes], sizeof(aTabViewItemIndex));
    
    aTabView = (PTYTabView *)[sender draggingSource];
    if(aTabView == nil)
	return (NO);

    aTabViewItem = [aTabView tabViewItemAtIndex: aTabViewItemIndex];
    if(aTabViewItem == nil)
	return (NO);

    // get the location and check if we should do an insert or add
    dropPoint = [sender draggingLocation];
    localPoint = [self convertPoint: dropPoint fromView: nil];
    if([self tabViewItemAtPoint: localPoint] != nil)
    {
	index = [self indexOfTabViewItem: [self tabViewItemAtPoint: localPoint]];

	// Check if we are dropping on the source tabViewItem
	if(aTabViewItem == [self tabViewItemAtPoint: localPoint])
	    return (NO);

	// Tell the tabViewItem under the dropPoint that it is not a drop target anymore
	if(index >= 0)
	    [(PTYTabViewItem *)[self tabViewItemAtIndex: index] resignDragTarget];
    }

    // If we are dragging the currently selected tabViewItem in the source, make the next or
    // previous one active
    if([aTabView selectedTabViewItem] == aTabViewItem)
    {
	if(aTabViewItemIndex > 0)
	    [aTabView selectTabViewItemAtIndex: (aTabViewItemIndex - 1)];
	else
	    [aTabView selectTabViewItemAtIndex: (aTabViewItemIndex + 1)];
    }

    // inform the delegates that we are performing a drag operation
    sourceDelegate = [aTabView delegate];
    targetDelegate = [self delegate];
    if([sourceDelegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[sourceDelegate tabViewWillPerformDragOperation: aTabView];
    if((targetDelegate != sourceDelegate) && [targetDelegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[targetDelegate tabViewWillPerformDragOperation: self];    
    
    // temporarily retain the tabViewItem
    [aTabViewItem retain];    
    
    // remove the tabViewItem from source
    [aTabView removeTabViewItem: aTabViewItem];
    // add the tabViewItem to ourselves at the appropriate index; or do an add
    if(index >= 0)
    {
	[self insertTabViewItem: aTabViewItem atIndex: index];
    }
    else
	[self addTabViewItem: aTabViewItem];
    // make it active
    [self selectTabViewItem: aTabViewItem];
    // release the tabViewItem
    [aTabViewItem release];

    // inform the delegates that we are done performing a drag operation
    if([sourceDelegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[sourceDelegate tabViewDidPerformDragOperation: aTabView];
    if((targetDelegate != sourceDelegate) && [targetDelegate conformsToProtocol: @protocol(PTYTabViewDelegateProtocol)])
	[targetDelegate tabViewDidPerformDragOperation: self];
    
    return (YES);    
}

- (void) concludeDragOperation: (id <NSDraggingInfo>) sender
{
}

- (float) maxLabelSize
{
    return maxLabelSize;
}

@end

/* 
   WkContextFolderIconViewController.m

   Context component table view controller
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: November 2004
   
   This file is part of the Etoile desktop environment.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>
#import <EtoileExtensions/UKDistibutedView.h>
#import "FilieCore/UKFolderIconViewController.h"
#import "WkContextViewController.h"
#import "WkContextFolderIconViewController.h"

@implementation WkContextFolderIconViewController

- (id) initWithView: (NSView *)view
{
    if ([super initWithView: view] != nil)
    {
        ASSIGN(iconView, view);
		iconViewController = [[UKFolderIconViewController alloc] init];
        return self;
    }
    
    return nil;
}

/*
 * Icon view data source methods
 */

#ifdef 0

-(int)			numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return [fileList count];
}

// -----------------------------------------------------------------------------
//  distributedView:positionForCell:atItemIndex:
//      Delegate method called by UKDistributedView to display each item.
//      Sets up the cell and returns the item's position.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(UKFinderIconCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (int)row
{
    UKFSItem*	fsItem = [fileList objectAtIndex: row];
	NSPoint     pos = [fsItem position];
    
    if( cell )
	{
		NSString*   dNam = [fsItem displayName];
		NSImage*	icn = [fsItem icon];
        NSColor*    labelCol = [fsItem labelColor];
		
		[cell setTitle: dNam];
		[cell setImage: icn];
        [cell resetColors];
        [cell setNameColor: [labelCol colorWithAlphaComponent: 0.5]];
        if( labelCol != [NSColor whiteColor] )
            [cell setSelectionColor: labelCol];
        if( searchString && [searchString length] > 0
            && [[fsItem displayName] rangeOfString: searchString options: NSCaseInsensitiveSearch].location == NSNotFound )
            [cell setAlpha: 0.3];
        else
            [cell setAlpha: 1.0];
	}
	
    if( pos.x == -1 && pos.y == -1 )
    {
        pos = [distributedView suggestedPosition];
        [fsItem setPosition: pos];
    }
    
	return pos;
}


// -----------------------------------------------------------------------------
//  distributedView:setPosition:forItemIndex:
//      Delegate method called by UKDistributedView when an item has been moved
//      through dragging it.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)			distributedView: (UKDistributedView*)distributedView
						setPosition: (NSPoint)pos
						forItemIndex: (int)row
{
    UKFSItem*	fsItem = [fileList objectAtIndex: row];
    [fsItem setPosition: pos];
}


// -----------------------------------------------------------------------------
//  distributedView:setObjectValue:forItemIndex:
//      Delegate method called by UKDistributedView when an item has been
//      inline-edited. This is where we rename the item.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)			distributedView: (UKDistributedView*)distributedView
						setObjectValue: (id)val
						forItemIndex: (int)row
{
    if( !newItems )
    {
        UKFSItem*	fsItem = nil;
        
        @synchronized(self)
        {
            NSLog(@"setObjectValue - newItems FLAGGED");
            newItems = [[NSMutableArray alloc] init];
            fsItem = [[[fileList objectAtIndex: row] retain] autorelease];
        }
        
        [fsItem setName: val];
        usleep(1000);   // Give kqueue thread a chance to ignore update notification.
        
        @synchronized(self)
        {
            NSLog(@"setObjectValue - newItems UN-FLAGGED");
            [newItems release];
            newItems = nil;
        }
    }
    else
        NSBeep();
}


// -----------------------------------------------------------------------------
//  distributedView:cellDoubleClickedAtItemIndex:
//      Delegate method called by UKDistributedView when an item has been
//      double-clicked. This is where we open all selected items.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (int)item
{
    NSEnumerator*   enny = [fileListView selectedItemEnumerator];
    NSNumber*       index;
    
    while( (index = [enny nextObject]) )
        [[fileList objectAtIndex: [index intValue]] openViewer: self];
}


// -----------------------------------------------------------------------------
//  distributedView:toolTipForItemAtIndex:
//      Delegate method called by UKDistributedView when it needs to know what
//      tool tip ("help tag") to display for an item. This is where we display
//      the full, un-shortened name.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)    distributedView: (UKDistributedView*)distributedView toolTipForItemAtIndex: (int)row
{
    return [[fileList objectAtIndex: row] displayName];
}


// -----------------------------------------------------------------------------
//  distributedView:itemIndexForString:options:
//      Delegate method called by UKDistributedView when it needs to know what
//      item to select during type-ahead selection. Also called by the filter
//      field to select the first matching item.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(int)  distributedView: (UKDistributedView*)distributedView itemIndexForString: (NSString*)str options: (unsigned)opts
{
    NSEnumerator*   enny = [fileList objectEnumerator];
    UKFSItem*       fsItem;
    UKFSItem*       foundItem = nil;
    int             foundItemIndex = -1, x = -1;
    
    while( (fsItem = [enny nextObject]) )
    {
        x++;
        
        if( opts == (NSAnchoredSearch | NSCaseInsensitiveSearch) )
        {
            NSComparisonResult comp = [[fsItem displayName] compare: str options: NSCaseInsensitiveSearch];
            if( comp == NSOrderedDescending || comp == NSOrderedSame )
            {
                if( foundItem != nil )
                {
                    comp = [[fsItem displayName] compare: [foundItem displayName] options: NSCaseInsensitiveSearch];
                    if( comp == NSOrderedAscending )
                    {
                        foundItem = fsItem;
                        foundItemIndex = x;
                    }
                }
                else
                {
                    foundItem = fsItem;
                    foundItemIndex = x;
                }
            }
        }
        else
        {
            NSRange found = [[fsItem displayName] rangeOfString:str options: opts];
            if( found.location != NSNotFound )
            {
                foundItemIndex = x;
                
                if( [self itemIsVisible: fsItem] )  // Visible? Good enough.
                    return foundItemIndex;
                // Not visible? Keep looking for another, possibly visible item so we avoid scrolling stuff away the user wants.
            }
        }
    }
    
    return foundItemIndex;
}


// -----------------------------------------------------------------------------
//  distributedView:writeItems:toPasteboard:
//      Delegate method called by UKDistributedView when a drag has been
//      started. UKDV automatically adds the item positions to the drag and
//      generates a nice drag image.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)				distributedView: (UKDistributedView*)dv writeItems:(NSArray*)indexes
						toPasteboard: (NSPasteboard*)pboard
{
    NSEnumerator*   enny = [indexes objectEnumerator];
    NSNumber*       index;
    NSMutableArray* filenames = [NSMutableArray array];
    
    while( (index = [enny nextObject]) )
    {
        UKFSItem*   item = [fileList objectAtIndex: [index intValue]];
        NSString*   thePath = [item path];
        [filenames addObject: thePath];
    }
    
    [pboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: nil];
    [pboard setPropertyList: filenames forType: NSFilenamesPboardType];
    
    return YES;
}


// -----------------------------------------------------------------------------
//  distributedView:validateDrop:proposedItem:
//      Delegate method called by UKDistributedView when a drag has entered
//      this view. It will propose to have the drop occur on the item that
//      the mouse is over, or -1 to mean inside the view itself.
//
//      This returns NSDragOperationNone to say it doesn't accept the drag,
//      otherwise says how it will accept the drag.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSDragOperation)  distributedView: (UKDistributedView*)dv validateDrop: (id <NSDraggingInfo>)info
						proposedItem: (int*)row
{
    if( (*row) != -1 )
    {
        UKFSItem*       target = [fileList objectAtIndex: *row];
        
        if( ![target isDirectory] )     // We can only drop into folders.
            *row = -1;                  // Drop in container if it's on top of a file.
        else
        {
            NSPasteboard*   pb = [info draggingPasteboard];
            NSArray*        files = [pb propertyListForType: NSFilenamesPboardType];
            
            if( [files containsObject: [target path]] ) // Attempt to drop an item on itself? User is probably moving it just a little.
                *row = -1;      // Make the target the container.
        }
    }
    
    return NSDragOperationEvery;
}


// -----------------------------------------------------------------------------
//  itemForPath:
//      Return the item at the specified path in this viewer, or NIL if this
//      viewer doesn't contain the specified item.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(UKFSItem*)    itemForPath: (NSString*)path
{
    NSEnumerator*   enny = [fileList objectEnumerator];
    UKFSItem*       item = nil;
    
    while( (item = [enny nextObject]) )
    {
        if( [[item path] isEqualToString: path] )
            return item;
    }
    
    return nil;
}


// -----------------------------------------------------------------------------
//  distributedView:acceptDrop:onItem:
//      The user has dropped something on our icon view. Actually drop the
//      items now and add them to our file list (i.e. move/copy the files).
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)  distributedView: (UKDistributedView*)dv acceptDrop: (id <NSDraggingInfo>)info
						onItem: (int)row
{
    NSPasteboard*   pb = [info draggingPasteboard];
    NSPoint         pos = [info draggedImageLocation];
    NSArray*        positions = [dv positionsOfItemsOnPasteboard: pb forImagePosition: pos];
    NSArray*        files = [pb propertyListForType: NSFilenamesPboardType];
    NSEnumerator*   enny = [files objectEnumerator];
    NSEnumerator*   posEnny = [positions objectEnumerator];
    NSString*       currFile;
    NSValue*        currPos;
    
    // Loop over the files dropped:
    while( (currFile = [enny nextObject]) )
    {
        // Determine the position this item was dropped at:
        currPos = [posEnny nextObject];
        if( currPos )
            pos = [currPos pointValue];
        else
            pos = [dv suggestedPosition];
        UKFSItem*   item = [self itemForPath: currFile];
        
        if( !item ) // It wasn't an item in here that was just moved?
        {
            NSString*   newPath = [folderPath stringByAppendingPathComponent: [currFile lastPathComponent]];
            BOOL        success = NO;
            
            // Copy/Link/Move the object over and add an item for it:
            
            if( [info draggingSourceOperationMask] == NSDragOperationCopy )
                success = [[NSFileManager defaultManager] copyPath: currFile
                                                            toPath: newPath
                                                            handler: nil];
            else if( [info draggingSourceOperationMask] == NSDragOperationLink )
                success = [[NSFileManager defaultManager] linkPath: currFile
                                                            toPath: newPath
                                                            handler: nil];
            else
                success = [[NSFileManager defaultManager] movePath: currFile
                                                            toPath: newPath
                                                            handler: nil];
            if( success )
            {
                NSDictionary* attrs = [[NSFileManager defaultManager] fileAttributesAtPath: newPath traverseLink: YES];
                item = [[[UKFSItem alloc] initWithPath: newPath isDirectory: [[attrs objectForKey: NSFileType] isEqualToString: NSFileTypeDirectory]
                                            withAttributes: attrs owner: self] autorelease];
                [fileList addObject: item];
            }
            
        }
        
        // Place the (possibly new) item at its new position:
        [item setPosition: pos];
    }
    
    [fileListView reloadData];  // Update the icon view.
    
    return YES;     // We're accepting this drop.
}


// -----------------------------------------------------------------------------
//  distributedView:dragEndedWithOperation:
//      The user has dropped something from our icon view somewhere else.
//      If it was dropped on the trash, we re-route this to mean "delete".
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)		distributedView: (UKDistributedView*)dv dragEndedWithOperation: (NSDragOperation)operation
{
    if( operation == NSDragOperationDelete )
        [dv delete: nil];   // Just pretend somebody had chosen the "clear" menu item.
}


// -----------------------------------------------------------------------------
//  delete:
//      Someone pressed the "delete" key or dropped some items on the trash.
//      Move them to the trash using the appropriate NSWorkspace method.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) delete: (id)sender
{
    NSEnumerator*   enny = [fileListView selectedItemEnumerator];
    NSNumber*       itemNb = nil;
    NSMutableArray* arr = [NSMutableArray array];
    int             tag = 0;
    
    while( (itemNb = [enny nextObject]) )
        [arr addObject: [[[fileList objectAtIndex: [itemNb intValue]] path] lastPathComponent]];
    
    [[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
                                    source: folderPath destination: @""
                                    files: arr tag: &tag];
}


// -----------------------------------------------------------------------------
//  distributedView:draggingSourceOperationMaskForLocal:
//      The user is trying to drag something out of this view. Happily say yes.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSDragOperation)  distributedView: (UKDistributedView*)dv draggingSourceOperationMaskForLocal: (BOOL)local
{
    return NSDragOperationEvery;
}

#endif

- (void) reload
{
    [iconViewController loadFolderContents: nil];
}

- (void) setContext: (EXContext *)newContext
{
	[super setContext: newContext];
	[iconViewController setURL: [[self context] URL]];
}

@end

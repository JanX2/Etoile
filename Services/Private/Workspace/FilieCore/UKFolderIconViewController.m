/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderIconViewController.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-04-15  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFolderIconViewController.h"

#ifndef __ETOILE__
#import "UKDirectoryEnumerator.h"
#endif

#import "UKFSItemViewProtocol.h"

#ifndef __ETOILE__
#import "UKDistributedView.h"
#import "UKFinderIconCell.h"
#import "NSImage+NiceScaling.h"
#import "NSFileManager+NameForTempFile.h"

#else
#import <EtoileExtensions/UKDistributedView.h>
#import <EtoileExtensions/UKFinderIconCell.h>
#import <EtoileExtensions/NSImage+NiceScaling.h>
#import <EtoileExtensions/NSFileManager+NameForTempFile.h>

#endif

#import "UKFSItem.h"

#ifndef __ETOILE__
#import "UKKQueue.h"

#else
#import <EtoileExtensions/UKKQueue.h>

#endif

#import "UKMainThreadActionQueue.h"

#ifndef __ETOILE__
#import "UKPushbackMessenger.h"

#else
#import <EtoileExtensions/UKPushbackMessenger.h>

#endif

#import "UKFolderMetaStorage.h"
#import "UKFolderDataSource.h"


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

// List of int array-entries for the various item sizes.
//  Each item's index corresponds to the tag of one menu item.
#define ICON_SIZES      16, 32, 48, 64, 128, 256


@implementation UKFolderIconViewController

// -----------------------------------------------------------------------------
//  Factory methods according to UKFSItemViewer protocol:
// -----------------------------------------------------------------------------

+(id)   viewForItemAtPath: (NSString*)path
{
	return [[[UKFolderIconViewController alloc] initWithPath: path] autorelease];
}


+(id)   viewForItemAtURL: (NSURL*)url
{
	return [[[UKFolderIconViewController alloc] initWithURL: url] autorelease];
}


// -----------------------------------------------------------------------------
//  initWithPath:
//      Crate a viewer for the item at the specified path. * DEPRECATED *
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)			initWithPath: (NSString*)path
{
    self = [self initWithURL: [NSURL fileURLWithPath: path]];
    return self;
}


// -----------------------------------------------------------------------------
//  initWithURL:
//      Crate a viewer for the item at the specified URL.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)			initWithURL: (NSURL*)url
{
	self = [super init];
	if( self )
	{
        reloadIconQueue = [[UKMainThreadActionQueue alloc] initWithMessage: @selector(loadItemIcon:)];
        iconSize = NSMakeSize(48,48);
        forceShowList = [[NSMutableArray alloc] initWithObjects: @".htaccess", nil];
        hideDotFiles = YES;
        showIconPreviews = YES;
        keepArrangedMode = -1;
		
		[self setURL: url];
        
        [self finishCreation];
	}
	
	return self;
}

- (void) setURL: (NSURL *)url
{
		[folderPath release];
		[fileList release];
		[kqueue release];
		
		folderPath = [[url path] copy];
		fileList = [[NSMutableArray alloc] init];
		kqueue = [[UKKQueue alloc] init];
		[kqueue setDelegate: self];
		[kqueue addPathToQueue: folderPath];
        dataSource = [self newDataSourceForURL: url];
        [dataSource setDelegate: self];
        filieStore = [self newMetaStorageForURL: url];
}


// -----------------------------------------------------------------------------
//  dealloc:
//      Destructor.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)		dealloc
{
    [dataSource release];
	[searchString release];
	searchString = nil;
	[folderPath release];
	[fileList release];
	[coalescer release];
	[kqueue release];
    [hiddenList release];
    [forceShowList release];
    [reloadIconQueue release];
    [filieStore release];
    [newItems release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//  newDataSourceForURL:
//      Method that creates the data source for this viewer. Called by
//      finishCreation. Provided for subclasses which may wish to get their
//      file list from another data source.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id<UKFSDataSource,NSObject>)  newDataSourceForURL: (NSURL*)url
{
    return [[UKFolderDataSource alloc] initWithURL: url];
}


// -----------------------------------------------------------------------------
//  newMetaStorageForURL:
//      Method that creates the metadata storage for this viewer. Called by
//      finishCreation. Provided for subclasses which may wish to get their
//      metadata from another storage.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(UKFolderMetaStorage*)  newMetaStorageForURL: (NSURL*)url
{
    return [[UKFolderMetaStorage alloc] initForURL: url];
}


// -----------------------------------------------------------------------------
//  recalcCellSize:
//      Recalculate and change the cell size of our icon view based on the
//      iconSize instance variable.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSSize)   recalcCellSize
{
    NSSize cellSize = iconSize;
    
    cellSize.width += cellSize.width -1;
    cellSize.height += 22 +(UKFIC_TEXT_VERTMARGIN *2) + UKFIC_SELBOX_VERTMARGIN +(UKFIC_SELBOX_OUTLINE_WIDTH *2) +(UKFIC_IMAGE_VERTMARGIN *2);
    cellSize.width += (UKFIC_TEXT_HORZMARGIN *2) +(UKFIC_SELBOX_OUTLINE_WIDTH *2) +(UKFIC_IMAGE_HORZMARGIN *2);
	
    [fileListView setCellSize: cellSize];
    
    return cellSize;
}


// -----------------------------------------------------------------------------
//  finishCreation:
//      Instead of awakeFromNib, because awake gets called when UKNibOwner loads
//      our NIB, but at that time the object hasn't been fully constructed yet.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)			finishCreation
{
	UKFinderIconCell*   fCell = [[[UKFinderIconCell alloc] init] autorelease];
	[fCell setEditable: YES];
	[fileListView setPrototype: fCell];
	[fileListView setDragMovesItems: YES];
	[fileListView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
    
    coalescer = [[UKPushbackMessenger alloc] initWithTarget: fileListView];
    [coalescer setDelay: 1.0];
    [coalescer setMaxPushTime: 4.0];
	
	#ifndef __ETOILE__
	[progress setUsesThreadedAnimation: YES];
				
	// Make sure we get spatial metaphor right and position our window where user left it:
	if( filieStore )
    {
        [[fileListView window] setFrame: [filieStore displayRect] display: NO];
        NSNumber*   num = [filieStore objectForKey: @"snapToGrid"];
        if( num )
            [fileListView setSnapToGrid: [num boolValue]];
        num = [filieStore objectForKey: @"showIconPreviews"];
        if( num )
        {
            showIconPreviews = [num boolValue];
            [previewButton setState: showIconPreviews];
        }
        NSValue*    val = [filieStore objectForKey: @"iconSize"];
        if( val )
            iconSize = [val sizeValue];
        NSString*    str = [filieStore objectForKey: @"filterString"];
        if( str )
        {
            [filterField setStringValue: str];
            [self setSearchString: str];
        }
        num = [filieStore objectForKey: @"keepArrangedMode"];
        if( num )
            keepArrangedMode = [num intValue];
    }
	
	#else
	
	#endif
	
    [self recalcCellSize];
    
    // Now finally kick off loading of our files:
	[NSThread detachNewThreadSelector:@selector(loadFolderContents:) toTarget:self withObject: nil];
}


// -----------------------------------------------------------------------------
//  loadItemIcon:
//      Add the specified UKFSItem to our queue of objects to get a loadItemIcon
//      message.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)   loadItemIcon: (UKFSItem*)item
{
    if( [self itemIsVisible: item] )
        [reloadIconQueue addObject: item];
}


// -----------------------------------------------------------------------------
//  startProgress:
//      Start the progress indicator spinning.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) startProgress: (NSString*)statusText
{
    [self startProgress: statusText recordTiming: NO];
}


// -----------------------------------------------------------------------------
//  startProgress:recordTiming:
//      Start the progress indicator spinning. Can be called from another
//      thread. Calls to this can be nested. Only the outermost call's
//      statusText is displayed, all sub-tasks aren't shown.
//
//      NOTE: recordTiming: is only for debugging purposes. It'll be turned off
//      once we release.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) startProgress: (NSString*)statusText recordTiming: (BOOL)time
{
    #ifndef __ETOILE__
	if( progressCount == 0 )
    {
        [progress performSelectorOnMainThread:@selector(startAnimation:) withObject:self waitUntilDone: NO];
        [status performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat: @"%d items - %@", [fileList count], statusText] waitUntilDone: NO];
        if( time )
            progressStarted = [[NSDate date] timeIntervalSinceReferenceDate];
    }
    
    progressCount++;
	#endif
}


// -----------------------------------------------------------------------------
//  stopProgress:
//      Balance a call to startProgress: or startProgress:recordTiming: once you
//      are done.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) stopProgress
{
    #ifndef __ETOILE__
	progressCount--;
    
    if( progressCount == 0 )
    {
        NSTimeInterval  ti = [[NSDate date] timeIntervalSinceReferenceDate] -progressStarted;
        [progress performSelectorOnMainThread:@selector(stopAnimation:) withObject:self waitUntilDone: NO];
        [status performSelectorOnMainThread:@selector(setStringValue:) withObject: [NSString stringWithFormat: @"%d items - took %f seconds", [fileList count], ti] waitUntilDone: NO];
    }
	#endif
}


// -----------------------------------------------------------------------------
//  UKDistributedView delegate methods that start/stop the progress indicator
//  when the view is busy:
// -----------------------------------------------------------------------------

-(void) distributedViewDidStartCachingItems: (UKDistributedView*)view
{
	[self startProgress: @"Cacheing items..."];
}


-(void) distributedViewWillEndCachingItems: (UKDistributedView*)view
{
	[self stopProgress];
}


// -----------------------------------------------------------------------------
//  itemForFile:
//      Return the UKFSItem for the specified file name (not path). Returns NIL
//      If there is no such file.
//
//      FIX ME! Right now this tries to pick up its search where it last left
//      off, which is an optimization, but it still performs a linear search.
//      Since this is called during loading, we may want to optimize this a lot
//      more, especially for sequential access of our file list.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(UKFSItem*)    itemForFile: (NSString*)name
{
    int     flc = [fileList count];
    
    if( lastCheckedIndex >= flc )
        lastCheckedIndex = 0;

    UKFSItem*       item = nil;
    int             x, start = lastCheckedIndex, end = flc, y;
    
    for( y = 0; y < 2; y++ )    // Try twice in case we need to wrap around.
    {
        for( x = start; x < end; x++ )
        {
            item = [fileList objectAtIndex: x];
            if( [[item name] isEqualToString: name] )
                return item;
        }
        
        // Wrap around index:
        start = 0;
        end = lastCheckedIndex;
    }
    
    return nil;
}


// -----------------------------------------------------------------------------
//  loadFolderContents:
//      Called in a new thread whenever the folder contents need to be updated.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) loadFolderContents: (id)sender
{
    if( !newItems )     // newItems functions as flag to avoid re-entrancy.
    {
        NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
        [dataSource reload: sender];    // Tell FSItem data source to list files:
        [pool release];
    }
}


// -----------------------------------------------------------------------------
//  dataSourceWillReload:
//      Called by the FSItem data source before it starts telling us about the
//      files it has available.
//
//      This makes a new array into which the new list of files is loaded. That
//      way, the user can still work with the old list until the update has
//      finished. However, since old items are shared between the two sources,
//      the user will already get part of the update while working with the old
//      list.
//
//      *this runs in another thread*
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) dataSourceWillReload: (id<UKFSDataSource>)dSource
{
    [self startProgress: @"Loading files..." recordTiming: YES];
    
	// FIXME: @synchronised
    //@synchronized(self)
    //{
        NSLog(@"reload - newItems FLAGGED");
        newItems = [[NSMutableArray alloc] init];
        finalItems = [[NSMutableArray alloc] init];
        if( [fileList count] == 0 ) // Was empty till now? First load!
            fileList = [finalItems retain]; // Let user watch while it's loading.
    //}
}


// -----------------------------------------------------------------------------
//  listItem:withAttributes:source:
//      Called by the FSItem data source for each file it offers us. We ignore
//      invisible files if the user wants us to. This works on a list that is
//      not displayed in a window, but carries over old FSItems.
//
//      *this runs in another thread*
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) listItem: (NSURL*)url withAttributes: (NSDictionary*)attrs source: (id<UKFSDataSource>)dSource
{
    // We're at file system root? Hide all items named in the .hidden file:
    if( !hiddenList && [folderPath isEqualToString: @"/"] )
    {
        hiddenList = [[NSString stringWithContentsOfFile: @"/.hidden"] componentsSeparatedByString: @"\n"];
        hiddenList = [[hiddenList arrayByAddingObject: @"Network"] retain];  // We also hide "Network", because we display that in a special location.
    }
    
    NSString*       filePath = [url path];
    NSString*       fname = [filePath lastPathComponent];
    BOOL            showFile = [fname characterAtIndex:0] != '.' || (hideDotFiles == NO);   // Begins with dot and we're not supposed to show dotted files? hide!
    
    if( !showFile ) // Hidden, but user added it to the "always show" list?
        showFile = [forceShowList containsObject: fname];
    
    if( showFile )  // Showing, but user (or .hidden file) added it to "always hide" list?
        showFile = ![hiddenList containsObject: fname];
    
    if( showFile )
        showFile = ![[attrs objectForKey: UKItemIsInvisible] boolValue];
    
    if( showFile )  // All these checks still mean we should show 'em?
    {
        UKFSItem*       theItem = nil;
        NSDictionary*   moreInfo = [filieStore dictionaryForFile: fname];
        BOOL            alreadyLoaded = NO;
        
        if( fileList != finalItems )
            theItem = [self itemForFile: fname];
        
        if( !theItem )
            theItem = [[[UKFSItem alloc] initWithURL: url isDirectory: [[attrs objectForKey: NSFileType] isEqualToString: NSFileTypeDirectory]
                                            withAttributes: attrs owner: self] autorelease];
        else
        {
            [theItem setAttributes: attrs];
            alreadyLoaded = YES;
        }
        
        if( theItem )
        {
            if( moreInfo || alreadyLoaded )  // Item we already know?
            {
                if( !alreadyLoaded )
                    [theItem setPosition: [[moreInfo objectForKey: @"position"] pointValue]];
                [finalItems addObject: theItem];
            }
            else
                [newItems addObject: theItem];  // Remember for later. We can't pick a new position yet, because we don't know what spaces are occupied before everything's been loaded.
        }
    }
}


// -----------------------------------------------------------------------------
//  dataSourceWillRecache:
//      Called by the FSItem data source occasionally when it hits a short pause
//      in listing files, e.g. when it's replenishing its cache. If this is the
//      first time we're listing items in our window, this lets the user watch
//      and causes a redraw of the icon view.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) dataSourceWillRecache: (id<UKFSDataSource>)dSource
{
    if( fileList == finalItems )    // Let user watch if this is first time we're loading.
        [fileListView performSelectorOnMainThread:@selector(noteNumberOfItemsChanged) withObject:nil waitUntilDone: NO];
}


// -----------------------------------------------------------------------------
//  dataSourceDidReload:
//      Called by the FSItem data source once it's finished telling us about its
//      list of files. We know swap the old list with the new, updated list and
//      quickly pick positions for all newly-arrived items.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) dataSourceDidReload: (id<UKFSDataSource>)dSource
{
    // Add all new items in one fell swoop:
    [fileListView setMultiPositioningMode: YES];    // Caches the last free position so we don't have to skip all those occupied slots again.
    NSEnumerator*   enny = [newItems objectEnumerator];
    UKFSItem*       theItem = nil;
    
    while( (theItem = [enny nextObject]) )
    {
        NSPoint pos = [fileListView suggestedPosition]; // Picks a free position that lies on the grid.
        [theItem setPosition: pos];
        [finalItems addObject: theItem];
    }
    [fileListView setMultiPositioningMode: NO];
    
    // Re-sort if needed:
    if( keepArrangedMode >= 0 )
        [self rearrangeItemsByTag: keepArrangedMode];
    
	// FIXME: @synchronized
    //@synchronized(self)
    //{
        // Let user see new stuff:
        [fileList release];
        fileList = finalItems;  // Swap in updated list.
        finalItems = nil;
        
        [fileListView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone: NO];
        
        // Clean up:
        [self stopProgress];
    
        NSLog(@"reload - newItems UN-FLAGGED");
        [newItems release];
        newItems = nil;     // newItems doubles as a flag for finding out whether we're busy reloading. Clear flag!
    //}
}


// -----------------------------------------------------------------------------
//  fsDataSource:
//      Return our FSItem data source.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)   fsDataSource
{
    return dataSource;
}


// -----------------------------------------------------------------------------
//  fileStorePath:
//      Return the path to use for our metadata store. * DEPRECATED *
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)	fileStorePath
{
	return [folderPath stringByAppendingPathComponent: @".Filie_Store"];
}


// -----------------------------------------------------------------------------
//  displayName:
//      Return the display name for this viewer, to be used in GUI lists etc.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)	displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath: folderPath];
}


// -----------------------------------------------------------------------------
//  searchString:
//      Return the string we're filtering by.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString *) searchString
{
    return searchString; 
}

// -----------------------------------------------------------------------------
//  setSearchString:
//      Specify the string to filter by. Called by our filter field.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) setSearchString: (NSString *) theSearchString
{
    if (searchString != theSearchString)
    {
        [searchString release];
        searchString = [theSearchString retain];
        NSLog(@"searching for: %@", searchString);
        [fileListView selectItemContainingString: searchString];
        [fileListView setNeedsDisplay: YES];
    }
}


// -----------------------------------------------------------------------------
//  itemNeedsDisplay:
//      Find the specified item and make the distributed view update it.
//
//      FIX ME! We could probably optimize this by just taking the item's
//      position directly and adding a method to UKDistributedView for updating
//      an item at a specific coordinate.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) itemNeedsDisplay: (UKFSItem*)item
{
    int ind = [fileList indexOfObject: item];
    [fileListView itemNeedsDisplay: ind];
}


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
	
    /*
    while( (index = [enny nextObject]) )
        [[fileList objectAtIndex: [index intValue]] openViewer: self];
	 */
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


// -----------------------------------------------------------------------------
//  createNewFolder:
//      The "new folder" menu item.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)     createNewFolder: (id)sender
{
    NSString*   path = [folderPath stringByAppendingPathComponent: NSLocalizedString(@"New Folder",@"")];
    path = [[NSFileManager defaultManager] uniqueFileName: path];
    [[NSFileManager defaultManager] createDirectoryAtPath: path attributes: [NSDictionary dictionary]];
}


// -----------------------------------------------------------------------------
//  changeItemSize:
//      Menu item action for the entries in the "icon size" popup menu.
//      This determines what size to switch to based on the menu item's tag and
//      then "scales" the item positions so it behaves as if the view was just
//      zoomed.
//
//      FIX ME! This could potentially cause a loss of precision. We may want
//      to instead keep the positions for 128x128 icon sizes in the metadata
//      store and multiply them by a factor for the smaller sizes upon display.
//      That way, changing the icon size will *never* modify item positions.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)     changeItemSize: (NSMenuItem*)sender
{
    int     idx = [sender tag];
    int     sizes[] = { ICON_SIZES };
    NSSize  oldSize = [fileListView cellSize];
    
    iconSize = NSMakeSize(sizes[idx], sizes[idx]);
    [self recalcCellSize];
    
    // Now "scale" item positions:
    float hscale = [fileListView cellSize].width / oldSize.width;
    float vscale = [fileListView cellSize].height / oldSize.height;
    
    NSEnumerator*   enny = [fileList objectEnumerator];
    UKFSItem*       item;
    
    while( (item = [enny nextObject]) )
    {
        NSPoint pos = [item position];
        
        pos.x *= hscale;
        pos.y *= vscale;
        
        [item setPosition: pos];
    }
    
    [fileListView reloadData];
}


// -----------------------------------------------------------------------------
//  changeShowIconPreview:
//      Button action for the "show icon preview" button. Toggles the option
//      and causes a repaint.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)     changeShowIconPreview: (NSButton*)sender
{
    showIconPreviews = !showIconPreviews;
    //[previewButton setState: showIconPreviews];
    [fileListView setNeedsDisplay: YES];
}


// -----------------------------------------------------------------------------
//  UKRearrangeStringCompareFunc:
//      Function used for sorting items by name. Case-insensitive. For items
//      that come up the same, this uses the file's actual name as a secondary
//      criterion.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

int UKRearrangeStringCompareFunc( id a, id b, void* context )
{
    NSString*   ap = [a valueForKeyPath: (NSString*)context];
    NSString*   bp = [b valueForKeyPath: (NSString*)context];
    
    if( !ap ) ap = @"";
    if( !bp ) bp = @"";
    
    int comp = [ap localizedCaseInsensitiveCompare: bp];
    if( comp == NSOrderedSame )
    {
        ap = [a name];
        bp = [b name];
        comp = [ap localizedCaseInsensitiveCompare: bp];
    }
    
    return comp;
}


// -----------------------------------------------------------------------------
//  UKRearrangeCompareFunc:
//      Function used for sorting items. For items that come up the same, this
//      uses the display name as a secondary criterion by calling
//      UKRearrangeStringCompareFunc, which in turn uses the actual name as a
//      final fallback that should ensure a stable sort order.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

int UKRearrangeCompareFunc( id a, id b, void* context )
{
    NSString*   ap = [a valueForKeyPath: (NSString*)context];
    NSString*   bp = [b valueForKeyPath: (NSString*)context];
    
    if( !ap ) { ap = @""; NSLog(@"."); }
    if( !bp ) { bp = @""; NSLog(@"."); }
    
    int comp = [ap compare: bp];
    if( comp == NSOrderedSame )
        comp = UKRearrangeStringCompareFunc( a, b, @"displayName" );
    return comp;
}


// -----------------------------------------------------------------------------
//  rearrangeItemsBy:
//      Menu item action for sorting items in the window. Uses the tag of the
//      menu item to determine the actual criterion. Calls rearrangeItemsByTag:
//      to do the actual work.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)     rearrangeItemsBy: (NSMenuItem*)sender
{
    [self rearrangeItemsByTag: [sender tag]];
}

// -----------------------------------------------------------------------------
//  keepArrangedBy:
//      Menu item action for keeping items sorted in the window. Uses the tag of
//      the menu item to determine the actual criterion. Changes the
//      keepArrangedMode accordingly.
//      Calls rearrangeItemsByTag: to do the actual work.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)    keepArrangedBy: (NSMenuItem*)sender
{
    keepArrangedMode = [sender tag];
    if( keepArrangedMode >= 0 )
        [self rearrangeItemsByTag: keepArrangedMode];
}


// -----------------------------------------------------------------------------
//  rearrangeItemsByTag:
//      Main sorting bottleneck. This actually repositions the items according
//      to the specified sort criterion.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         rearrangeItemsByTag: (int)idx
{
    NSString*       keys[6] = { @"displayName", @"attributes.NSFileModificationDate",
                                @"attributes.NSFileCreationDate", @"attributes.NSFileSize",
                                @"attributes.NSFileType", @"attributes.UKLabelNumber" };
    NSString*       sortKey = keys[ idx ];
    NSArray*        sortedList = [fileList sortedArrayUsingFunction: ((idx == 0) ? UKRearrangeStringCompareFunc : UKRearrangeCompareFunc)
                                    context: sortKey];
    NSEnumerator*   enny = [sortedList objectEnumerator];
    UKFSItem*       item = nil;
    int             x = 0;
    
    while( (item = [enny nextObject]) )
    {
        NSPoint pos = [fileListView itemPositionBasedOnItemIndex: x];
        [item setPosition: pos];
        
        x++;
    }
    
    [fileListView performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO];
}


// -----------------------------------------------------------------------------
//  showInfoPanel:
//      Show info panels for the selected items.
//
//      TODO: Write a variation of this that creates a single info panel for all
//      selected items and hook that up to Command-Shift-I or so.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction) showInfoPanel: (id)sender
{
    NSEnumerator*   enny = [fileListView selectedItemEnumerator];
    NSNumber*       index;
    
    while( (index = [enny nextObject]) )
        [[fileList objectAtIndex: [index intValue]] openInfoPanel: self];
}


// -----------------------------------------------------------------------------
//  validateMenuItem:
//      Make sure all menu and popup menu items are correctly enabled and
//      checked.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL) validateMenuItem: (id<NSMenuItem>)item
{
    if( [item action] == @selector(openDocument:)
        || [item action] == @selector(showInfoPanel:)
        || [item action] == @selector(delete:) )
        return [fileListView selectedItem] != -1;
    else if( [item action] == @selector(changeItemSize:) )
    {
        int     sizes[] = { ICON_SIZES };
        
        [item setState: (iconSize.width == sizes[ [item tag] ])];
        
        return YES;
    }
    else if( [item action] == @selector(keepArrangedBy:) )
    {
        [item setState: ([item tag] == keepArrangedMode)];
        
        return YES;
    }
    else
        return [self respondsToSelector: [item action]];
}


// -----------------------------------------------------------------------------
//  openDocument:
//      Action for the "open..." menu item.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) openDocument: (id)sender
{
    [self openSelectedFiles: sender];
}


// -----------------------------------------------------------------------------
//  openSelectedFiles:
//      Open the selected items. This simply fakes a double-click on one of the
//      selected items, which implicitly opens all others as well, after all.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) openSelectedFiles: (id)sender
{
	[self distributedView: fileListView cellDoubleClickedAtItemIndex: [fileListView selectedItem]];
}


// -----------------------------------------------------------------------------
//  saveFileStore:
//      Save our metadata to the store. This saves item positions, viewer
//      dimensions etc.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) saveFileStore
{
    [self startProgress: @"Saving item positions..." recordTiming: YES];

    NSEnumerator*           enny = [fileList objectEnumerator];
    UKFSItem*               item;
    
    // Save viewer-wide prefs:
    [filieStore setObject: [NSNumber numberWithBool: [fileListView snapToGrid]] forKey: @"snapToGrid"];
    [filieStore setObject: [NSValue valueWithSize: iconSize] forKey: @"iconSize"];
    [filieStore setObject: [NSNumber numberWithBool: showIconPreviews] forKey: @"showIconPreviews"];
    [filieStore setObject: [filterField stringValue] forKey: @"filterString"];
    [filieStore setObject: [NSNumber numberWithInt: keepArrangedMode] forKey: @"keepArrangedMode"];
    [filieStore setDisplayRect: [[fileListView window] frame]];

    // Save file icon positions to file store:
    while( (item = [enny nextObject]) )
    {
        NSPoint pos = [item position];
        NSMutableDictionary*    info = [filieStore newDictionaryForFile: [item name]];
        [info setObject: [NSValue valueWithPoint: pos] forKey: @"position"];
    }
        
    BOOL    ours = NO;
    @synchronized(self)
    {
        // Save changed file store:
        if( !newItems )
        {
            newItems = [[NSMutableArray alloc] init];    // Make sure this save doesn't cause an unnecessary reload of the view.
            ours = YES;
            NSLog(@"saveFileStore - newItems FLAGGED");
        }
    }
        
    [filieStore synchronize];
        
    if( ours )
    {
        // FIXME: @synchronized
		//@synchronized(self)
        //{
            [newItems release];
            newItems = nil;
            NSLog(@"saveFileStore - newItems UN-FLAGGED");
        //}
    }
    
    [self stopProgress];
}


// -----------------------------------------------------------------------------
//  retain:
//      Used during debugging. Can probably be deleted.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)   retain
{
    return [super retain];
}


// -----------------------------------------------------------------------------
//  windowWillClose:
//      User closed our window. Save and perform suicide.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) windowWillClose: (NSNotification*)notification
{
	[fileListView setDelegate: nil];
	[kqueue setDelegate: nil];
    
    [self saveFileStore];
}


// -----------------------------------------------------------------------------
//  performKeepArranged:
//      This is called whenever items can change and will enforce the sort order
//      of the "keep arranged" submenu, if the user requested sorting.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) performKeepArranged
{
    NSRect  box = [fileListView frame];
    box.size.width = [[fileListView enclosingScrollView] documentVisibleRect].size.width;
    [fileListView setFrame: box];
    [self rearrangeItemsByTag: keepArrangedMode];
}


// -----------------------------------------------------------------------------
//  windowDidResize:
//      Our window has resized. Enforce keep arranged.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) windowDidResize: (NSNotification*)notification
{
    if( keepArrangedMode >= 0 )
        [coalescer performKeepArranged];
}


// -----------------------------------------------------------------------------
//  path:
//      Return the folder path for which this viewer is responsible.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)	path
{
	return [[folderPath retain] autorelease];
}


// -----------------------------------------------------------------------------
//  isEqual:
//      Compare this item to another. For use with collection classes like
//      NSArray, but possibly broken.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)			isEqual: (NSObject<UKFSItemView>*)other
{
    BOOL        result = NO;
    
	if( [other isKindOfClass: [NSString class]] )
		result = [folderPath isEqualToString: (NSString*) other];
	else if( [other conformsToProtocol: @protocol(UKFSItemView)] )
		result = [folderPath isEqualToString: [other path]];
    else
        result = [folderPath isEqualToString: [other description]];

    return result;
}


// -----------------------------------------------------------------------------
//  hash:
//      hash for comparing this item to another. For use with collection classes
//      like NSArray, but possibly broken.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(unsigned)     hash
{
    return [folderPath hash];
}


// -----------------------------------------------------------------------------
//  kqueue:receivedNotification:forFile:
//      Our kqueue that watches for file change notifications has noticed a
//      change. Reload our folder's contents.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) kqueue: (UKKQueue*)kq receivedNotification: (NSString*)nm forFile: (NSString*)fpath
{
	if( !newItems )
		[NSThread detachNewThreadSelector:@selector(loadFolderContents:) toTarget:self withObject: nil];
}


// -----------------------------------------------------------------------------
//  windowWillUseStandardFrame:defaultFrame:
//      Implement smarter zooming of our window.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSRect)   windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
    return [fileListView windowFrameForBestSize];
}


// -----------------------------------------------------------------------------
//  itemIsVisible:
//      Return whether one of our FSItems is actually visible. Used to decide
//      which items to load first.
//
//      TODO: Could probably be optimized to get the position directly from the
//      item and then call a method on UKDistributedView that returns whether
//      an item is visible based on its position.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)                 itemIsVisible: (UKFSItem*)item
{
    int ind = [fileList indexOfObject: item];
    return [fileListView itemIsVisible: ind];
}


// -----------------------------------------------------------------------------
//  showIconPreview:
//      Return whether we want our icons to contain previews. Called by our
//      FSItems when they load their final icon.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)                 showIconPreview
{
    return showIconPreviews;
}


// -----------------------------------------------------------------------------
//  iconSizeForItem:
//      Return what size we want our icons to be. Called by our FSItems when
//      they load their final icons.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSSize)               iconSizeForItem: (UKFSItem*)item
{
    return iconSize;
}


// -----------------------------------------------------------------------------
//  controlTextDidChange:
//      Sent by our filter search field when it is modified. Triggers a new
//      search.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)    controlTextDidChange:(NSNotification *)notification
{
    [coalescer performSelector: @selector(setSearchString:) withObject: [[notification object] stringValue]];
}


// -----------------------------------------------------------------------------
//  description:
//      Makes our item show up a tad prettier in NSLog() statements.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)    description
{
    return [NSString stringWithFormat: @"UKFolderIconViewController { path = \"%@\" }", folderPath];
}

@end

/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFileInfoPanel.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-12-09  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <UnitKit/UnitKit.h>
#import "UKFileInfoPanel.h"
#import "UKFileInfoMixedValueIndicator.h"


@implementation UKFileInfoPanel

// -----------------------------------------------------------------------------
//  initWithDelegates:
//      Create a new info panel. This takes an array of delegates as its
//      parameter. Each of the delegates is asked for its attributes and
//      notified of changes as needed.
//
//      As with all delegates, this object does not retain its delegates. So
//      make sure they sign off from this object before they go away.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)               initWithDelegates: (NSArray*)dels
{
    self = [super init];
    if( !self )
        return nil;
    
    [self setDelegates: dels];
    
    return self;
}

-(void) dealloc
{
    [fileAttributes release];
    [delegates release];
    [[attributesTable window] close];
    
    [super dealloc];
}

// -----------------------------------------------------------------------------
//  setDelegates:
//      Change the list of delegates for this object. The delegate is not
//      retained.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) testSetDelegates
{
	NSArray *testDelegates = [NSArray arrayWithObjects: @"blabla", @"bip", nil];
	UKFileInfoPanel *infoPanel = [[UKFileInfoPanel alloc] initWithDelegates: testDelegates];
	NSArray *previousDelegates;
	
	previousDelegates = [self delegates];
	[infoPanel setDelegates: testDelegates];
	UKTrue([delegates isEqual: previousDelegates]);
}

-(void) setDelegates: (NSArray*)theDelegates
{
    if (delegates != theDelegates)
    {
        [delegates release];
        delegates = [[NSMutableArray alloc] init];
        NSEnumerator* enny = [theDelegates objectEnumerator];
        id  del;
        while( (del = [enny nextObject]) )
        {
            [delegates addObject: [NSValue valueWithNonretainedObject: del]];
        }
    }
}


// -----------------------------------------------------------------------------
//  delegates:
//      Returns an array of all the delegates registered with this object.
//      The array retains this object, even though this object's internal
//      list usually doesn't.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSArray*) delegates
{
    NSMutableArray*     outDels = [NSMutableArray array];
    NSEnumerator* enny = [delegates objectEnumerator];
    id  del;
    while( (del = [enny nextObject]) )
    {
        [outDels addObject: [del nonretainedObjectValue]];
    }
    
    return outDels;
}

// -----------------------------------------------------------------------------
//  fileAttributes:
//      Returns the dictionary of file attributes this panel is currently
//      displaying.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSDictionary*) fileAttributes
{
    return fileAttributes;
}


// -----------------------------------------------------------------------------
//  setFileAttributes:
//      Replaces the dictionary of file attributes this panel is currently
//      displaying. You usually don't want to use this if there's more than
//      one delegate for this panel.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) setFileAttributes: (NSDictionary*)theFileAttributes
{
    if (fileAttributes != theFileAttributes) {
        [fileAttributes release];
        fileAttributes = [theFileAttributes mutableCopy];
    }
}


// -----------------------------------------------------------------------------
//  addFileAttributes:
//      Adds all attributes from the specified dictionary to the dictionary of
//      attributes this object is displaying. If an attribute is not the same
//      as that in the dictionary, it is replaced with a mixed value indicator
//      object.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             addFileAttributes: (NSDictionary*)dict
{
    if( fileAttributes == nil )
    {
        fileAttributes = [dict mutableCopy];
        isMultipleSelection = NO;
    }
    else
    {
        isMultipleSelection = YES;

        NSEnumerator*   enny = [dict keyEnumerator];
        NSString*       key;
        
        while( (key = [enny nextObject]) )
        {
            id  objA, objB;
            
            objA = [fileAttributes objectForKey: key];
            objB = [dict objectForKey: key];
            
            if( ![objA isEqual: objB] )
            {
                // TODO: Load the proper indicator based on the key, so we can offer placeholder strings etc.
                //  Maybe load values from a .plist?
                [fileAttributes setObject: [UKFileInfoMixedValueIndicator indicator] forKey: key];
            }
        }
        
        NSMutableArray*    newKeys = [[[dict allKeys] mutableCopy] autorelease];
        [newKeys removeObjectsInArray: [fileAttributes allKeys]];
        
        enny = [newKeys objectEnumerator];
        
        while( (key = [enny nextObject]) )
        {
            // TODO: Load the proper indicator based on the key, so we can offer placeholder strings etc.
            //  Maybe load values from a .plist?
            [fileAttributes setObject: [UKFileInfoMixedValueIndicator indicator] forKey: key];
        }
    }
}


// -----------------------------------------------------------------------------
//  revert:
//      Clear our internal list of file attributes and refresh it by asking
//      the delegates to provide their attributes again.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)         revert: (id)sender
{
    NSEnumerator*           enny = [delegates objectEnumerator];
    NSValue*                currDel;
    
    [self setFileAttributes: nil];
    
    while( (currDel = [enny nextObject]) )
        [[currDel nonretainedObjectValue] provideAttributesToInfoController: self];
    
    [attributesTable reloadData];
}


// -----------------------------------------------------------------------------
//  ok:
//      Tell all delegates to apply the new file attributes to their files.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(IBAction)         ok: (id)sender
{
    NSEnumerator*           enny = [delegates objectEnumerator];
    NSValue*                currDel;
    
    while( (currDel = [enny nextObject]) )
        [[currDel nonretainedObjectValue] takeAttributes: fileAttributes fromInfoController: self];
}


// -----------------------------------------------------------------------------
//  makeDelegatesResign:
//      Tell all delegates to abort their little love affair with us. This is
//      usually called because the user closed our window and we want this
//      window to go away now.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             makeDelegatesResign
{
    NSArray*                dels = [[delegates copy] autorelease];  // Keep a copy so we're immune to changes caused by delegates to our list.
    NSEnumerator*           enny = [dels objectEnumerator];
    NSValue*                currDel;
    
    [self retain];  // Make sure that we don't go away until last one has signed off.
    
    while( (currDel = [enny nextObject]) )
        [[currDel nonretainedObjectValue] resignFromInfoController: self];
    
    [self autorelease];     // Necessary so windowDidClose can finish the notification without a crash.
}


// -----------------------------------------------------------------------------
//  windowDidClose:
//      Our window's been closed. Make all delegates resign so this object can
//      go away too.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) windowDidClose: (NSNotification*)notification
{
    [self makeDelegatesResign]; // Retains and autoreleases this object so it doesn't go away until notification has finished.
}

// ---------------------------------------------------------- 
// - isMultipleSelection:
// ---------------------------------------------------------- 
- (BOOL) isMultipleSelection
{
    return isMultipleSelection;
}

// ---------------------------------------------------------- 
// - setIsMultipleSelection:
// ---------------------------------------------------------- 
- (void) setIsMultipleSelection: (BOOL) flag
{
        isMultipleSelection = flag;
}


// -----------------------------------------------------------------------------
//  addDelegate:
//      Add a new delegate to our list of delegates. Delegates are *not*
//      retained by this object.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             addDelegate: (id)obj
{
    [delegates addObject: [NSValue valueWithNonretainedObject: obj]];
}


// -----------------------------------------------------------------------------
//  removeDelegate:
//      Remove a delegate from our list of delegates.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             removeDelegate: (id)obj
{
    [delegates removeObject: [NSValue valueWithNonretainedObject: obj]];
}


// -----------------------------------------------------------------------------
//  reopen:
//      Re-open this inspector (i.e. it was already open, but the user requested
//      it a second time). This reloads the window's data and brings the window
//      to the front.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             reopen: (id)sender
{
    [self revert: sender];
    [[attributesTable window] makeKeyAndOrderFront: sender];
}


// -----------------------------------------------------------------------------
//  Table view data source methods: (for debugging, mainly)
// -----------------------------------------------------------------------------

- (void)testWithTableView
{
	
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [fileAttributes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString*   currKey = [[fileAttributes allKeys] objectAtIndex: row];
    
    if( [[tableColumn identifier] isEqualToString: @"key"] )
        return currKey;
    else
        return [fileAttributes objectForKey: currKey];
}



@end

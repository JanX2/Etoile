/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFSItem.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-04-16  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFSItem.h"
#import "UKFSItemViewer.h"
#import "NSImage+NiceScaling.h"
#import "UKDirectoryEnumerator.h"
#import "UKFileIcon.h"
#import "UKFSDataSource.h"
#import "NSImage+Epeg.h"
#import "NSWorkspace+PreviewFile.h"
#import "UKFileInfoPanel.h"
#import <limits.h>


// -----------------------------------------------------------------------------
//  Globals:
// -----------------------------------------------------------------------------

static NSImage*                 sUKFSItemGenericFileIcon = nil;     // Is this still in use?
static NSImage*                 sUKFSItemGenericFolderIcon = nil;   // Is this still in use?


@implementation UKFSItem

// -----------------------------------------------------------------------------
//  initWithURL:isDirectory:withAttributes:owner:
//      Create a new item representing the item at the specified URL.
//
//      FIX ME! This shouldn't assume it's a file URL.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)	initWithURL: (NSURL*)furl isDirectory: (BOOL)n withAttributes: (NSDictionary*)attrs owner: (id)viewer
{
    self = [self initWithPath: [furl path] isDirectory: n withAttributes: attrs owner: viewer];
    
    return self;
}


// -----------------------------------------------------------------------------
//  initWithPath:isDirectory:withAttributes:owner:
//      Create a new item representing the item at the specified path.
//
//      * DEPRECATED * Use the URL variant if you're writing client code.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)	initWithPath: (NSString*)fpath isDirectory: (BOOL)n withAttributes: (NSDictionary*)attrs owner: (id)viewer
{
	self = [super init];
	if( self )
	{
		path = [fpath retain];
		iconSize = [viewer iconSizeForItem: self];
        position = NSMakePoint(-1,-1);
		
		if( sUKFSItemGenericFileIcon == nil )
            sUKFSItemGenericFileIcon = [[[UKFileIcon genericDocumentIcon] image] retain];

		if( sUKFSItemGenericFolderIcon == nil )
            sUKFSItemGenericFolderIcon = [[[UKFileIcon genericFolderIcon] image] retain];
        
        attributes = [attrs retain];
        
		isDirectory = n;
        owningViewer = viewer;
	}
	
	return self;
}


-(void) dealloc
{
    [infoPanel removeDelegate: self];
    [infoPanel release];
    
	[path release];
	[icon release];
	[attributes release];
	[displayName release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//  setName:
//      Rename the file this object is associated with.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) setName: (NSString*)nameStr
{
    if( [nameStr isEqualToString: displayName] )    // Is display name? No change.
        return;
    
	NSString*   newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent: nameStr];
    if( ![path isEqualToString: newPath] )  // No change? Skip this.
    {
        // FIX ME! Hand the actual renaming off to the owner's data source?
        if( [[NSFileManager defaultManager] movePath: path toPath: newPath handler: nil] )
            [self setPath: newPath];
    }
}


// -----------------------------------------------------------------------------
//  name:
//      Return the actual file name, including suffix and whatever.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)    name
{
    return [path lastPathComponent];
}


// -----------------------------------------------------------------------------
//  path:
//      Return the full file path, ending in the actual file name.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString *)	path
{
    return [[path retain] autorelease];
}


// -----------------------------------------------------------------------------
//  setPath:
//      Change the item's file path. This does *not* move the file, but rather
//      changes the file the item points to (e.g. after it's moved).
//
//      FIX ME! This should really be using a URL to allow for non-file items.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)	setPath: (NSString *)newPath
{
    if( path != newPath )
	{
		[path autorelease];
		path = [newPath retain];
        [self setDisplayName: nil];
	}
}


// -----------------------------------------------------------------------------
//  icon:
//      Return an NSImage with the icon to display for this file. If the file's
//      icon hasn't been loaded yet, initiate the load  and return a placeholder
//      icon instead.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSImage*)		icon
{
    @synchronized( self )
    {
        if( !icon )
        {
            BOOL            hasCustomIcon = !attributes || [[attributes objectForKey: UKItemHasCustomIcon] boolValue];
            NSString*       suf = [[path pathExtension] lowercaseString];
            
            [owningViewer loadItemIcon: self];
            
            if( !icon )
                icon = [[[owningViewer fsDataSource] placeholderIconForItem: [NSURL fileURLWithPath: path] attributes: attributes] retain];
                
            if( !icon )
            {
                if( isDirectory )
                    icon = [sUKFSItemGenericFolderIcon retain];
                else
                    icon = [sUKFSItemGenericFileIcon retain];
            }
        }
    }

    return icon;
}


// -----------------------------------------------------------------------------
//  displayName:
//      Return the file's display name. This may be a localized name (for apps,
//      or system directories like "Library" or "Pictures" or "Desktop"), or it
//      may be the file name with the extension hidden/shown as per the user's
//      prefs, or both.
//
//      The display name is fetched lazily and cached by the FSItem for faster
//      retrieval.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString *)	displayName
{
	if( !displayName )
		[self setDisplayName: [[NSFileManager defaultManager] displayNameAtPath: path]];
	
    return [[displayName retain] autorelease];
}


// -----------------------------------------------------------------------------
//  setDisplayName:
//      Change the cached display name of this file to be another one. Don't
//      know why we'd need this, but it was auto-generated by Accessorizer, so
//      I'll leave it in there for now.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)	setDisplayName: (NSString *)newDisplayName
{
    if( displayName != newDisplayName )
	{
		[displayName autorelease];
		displayName = [newDisplayName retain];
	}
}


// -----------------------------------------------------------------------------
//  iconSize:
//      Return the icon size to display this item's icon at.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSSize)	iconSize
{
    return iconSize;
}


// -----------------------------------------------------------------------------
//  setIconSize:
//      Change the icon size to display this item's icon at.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)	setIconSize: (NSSize)newIconSize
{
	iconSize = newIconSize;
	[icon autorelease];
	icon = nil;
}


// -----------------------------------------------------------------------------
//  openViewer:
//      Open a viewer for this item.
//
//      TODO: Maybe the viewer registry should do the file package check as well?
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) openViewer: (id)sender
{
    if( [[NSWorkspace sharedWorkspace] isFilePackageAtPath: path] )
        [[NSWorkspace sharedWorkspace] openFile: path];
    else
        [[[UKFSItemViewerRegistry sharedRegistry] viewerForItemAtPath: path] selectViewer];
}


// -----------------------------------------------------------------------------
//  openInfoPanel:
//      Open an info panel for this item.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) openInfoPanel: (id)sender
{
    if( !infoPanel )
        infoPanel = [[UKFileInfoPanel alloc] initWithDelegates: [NSArray arrayWithObject: self]];
    
    [infoPanel reopen: nil];    // Make info panel reflect our attributes.
}


// -----------------------------------------------------------------------------
//  provideAttributesToInfoController:
//      Add this file's attributes to the list of attributes in an info
//      panel/inspector.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) provideAttributesToInfoController: (id<UKFileInfoProtocol>)infoController
{
    [infoController addFileAttributes: attributes];
}


// -----------------------------------------------------------------------------
//  takeAttributes:fromInfoController:
//      When it gets this, each delegate should take the attributes passed
//      (which should be the same as fileAttributes) and apply them to itself.
//      If any item is a UKFileInfoMixedValueIndicator (call
//      isDifferentAcrossSelectedItems to determine this easily), it should be
//      ignored and the old value for this attribute be used.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) takeAttributes: (NSDictionary*)attrs fromInfoController: (id<UKFileInfoProtocol>)infoController
{
    // TODO!
}


// -----------------------------------------------------------------------------
//  resignFromInfoController:
//      An info controller (inspector or info panel) has been closed or for some
//      other reason no longer wishes to display our info. Dissociate ourselves
//      from it and, if it's our info panel, give up ownership of it.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) resignFromInfoController: (id<UKFileInfoProtocol>)infoController
{
    [infoController removeDelegate: self];
    if( infoController == infoPanel )   // It's our info window, not just an inspector?
    {
        [infoPanel release];    // Make sure it closes!
        infoPanel = nil;
    }
}


// -----------------------------------------------------------------------------
//  setPosition:
//      Change the position of this item in its viewer window (icon view).
//      This is in flipped, UKDistributedView coordinates.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         setPosition: (NSPoint)pos
{
    position = pos;
}


// -----------------------------------------------------------------------------
//  position:
//      Return the position of this item in its viewer window (icon view).
//      This is in flipped, UKDistributedView coordinates.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSPoint)      position
{
    return NSMakePoint(truncf(position.x), truncf(position.y));
}


// -----------------------------------------------------------------------------
//  attributes:
//      Return a file attributes dictionary for our file.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSDictionary*)    attributes
{
    return attributes;
}


// -----------------------------------------------------------------------------
//  setAttributes:
//      Change the file attributes dictionary for our file. This doesn't (yet?)
//      change the actual file's attributes. Should it? Or do we need a separate
//      accessor for that?
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)    setAttributes: (NSDictionary*)attrs
{
    if( attributes != attrs )
    {
        [attributes release];
        attributes = [attrs retain];
    }
}


// -----------------------------------------------------------------------------
//  isDirectory:
//      Return whether this item is a file or a directory.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL) isDirectory
{
    return [[attributes fileType] isEqualToString: NSFileTypeDirectory];
}


// -----------------------------------------------------------------------------
//  labelColor:
//      Return the color to use for this file's label metadata attribute.
//      Returns white for "no label" or "unsupported label number".
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSColor*)  labelColor
{
    static NSArray*    labels = nil;
    if( !labels )
        labels = [[NSArray arrayWithObjects: [NSColor whiteColor],
                                            [NSColor grayColor],
                                            [NSColor greenColor],
                                            [NSColor purpleColor],
                                            [NSColor blueColor],
                                            [NSColor yellowColor],
                                            [NSColor redColor],
                                            [NSColor orangeColor],
                                            nil] retain];
    
    int labelNum = attributes ? [[attributes objectForKey: UKLabelNumber] intValue] : 0;
    
    if( labelNum >= 8 )
        return [NSColor whiteColor];
    else
        return [labels objectAtIndex: labelNum];
}


// -----------------------------------------------------------------------------
//  loadItemIcon:
//      This method is called in its own thread to actually load the item of
//      this file. It gets the actual icon from the file system data source.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) loadItemIcon: (id)sender
{
	NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
	NSImage*        fileIcon = nil;
	
    fileIcon = [[owningViewer fsDataSource] iconForItem: [NSURL fileURLWithPath: path] attributes: attributes];
    
    @synchronized( self )
    {
        if( icon && fileIcon )
        {
            [icon autorelease];
            icon = nil;
        }
        if( fileIcon )
            icon = [fileIcon retain];
    }
    
	[(NSObject*)owningViewer performSelectorOnMainThread: @selector(itemNeedsDisplay:) withObject: self waitUntilDone: NO];
    
    [pool release];
}


@end

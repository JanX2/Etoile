/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderDataSource.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-12-10  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <EtoileExtensions/EtoileCompatibility.h>
#import <UnitKit/UnitKit.h>

/* For tests */
#import "UKFolderIconViewController.h"

#import "UKFolderDataSource.h"

#ifndef __ETOILE__
#import "UKDirectoryEnumerator.h"
#import "UKFileIcon.h"
#import "NSWorkspace+PreviewFile.h"
#import "NSImage+NiceScaling.h"

#else
#import <EtoileExtensions/NSImage+NiceScaling.h>

#endif


@implementation UKFolderDataSource

-(id) initForTest
{
	BOOL dummy;
	UKFolderIconViewController *viewController = 
		[[UKFolderIconViewController alloc] initWithPath: @"/"];
	
	self = (UKFolderDataSource *)[viewController newDataSourceForURL: 
		[NSURL fileURLWithPath: [viewController valueForKey: @"folderPath"]]];
	UKTrue([[NSFileManager defaultManager] fileExistsAtPath: folderPath isDirectory: &dummy]);
	UKNotNil([self delegate]);
	
	return self;
}

// -----------------------------------------------------------------------------
//  initWithURL:
//      Create a data source for the folder at the specified URL. This uses a
//      path internally because, obviously, a folder data source always deals
//      in local files, so there's no need to mess with URLs anymore.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(id)               initWithURL: (NSURL*)folder
{
    self = [super init];
    if( self )
    {
        folderPath = [[folder path] retain];
    }
    
    return self;
}

-(void) dealloc
{
    [folderPath release];
    
    [super dealloc];
}


// -----------------------------------------------------------------------------
//  reload:
//      Request from the data source that it send the delegate its list of files.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) testReload
{
	UKNotNil(delegate);
	/*
	UKTrue([delegate repondsToSelector: @selector(dataSourceWillReload:)]);
	UKTrue([delegate repondsToSelector: @selector(listItem:withAttributes:source:)]);
	UKTrue([delegate repondsToSelector: @selector(dataSourceDidReload:)]);
	 */
}

-(void) reload: (id)sender
{
	NSLog(@"Data source reload with path %@ delegate", folderPath, delegate);
	
	#ifdef __ETOILE__
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator*  di = [fm enumeratorAtPath: folderPath];

	if( di )
	{
		[delegate dataSourceWillReload: self];
		
		NSString*		filePath = nil;
		int             x = 0;
		
		[di skipDescendents];
		while( (filePath = [di nextObject]) )
		{
            [delegate listItem: [NSURL fileURLWithPath: filePath] withAttributes: [di fileAttributes] source: self];
			NSLog(@"listItem with path %@", filePath);
		}
        
       [delegate dataSourceDidReload: self];
	}
	#else
	UKDirectoryEnumerator*  di = [[[UKDirectoryEnumerator alloc] initWithPath: folderPath cacheSize: 64] autorelease];

	if( di )
	{
       [delegate dataSourceWillReload: self];
        
		NSString*		filePath = nil;
		int             x = 0;
        
		[di setDesiredInfo: kFSCatInfoFinderInfo | kFSCatInfoNodeFlags | kFSCatInfoCreateDate | kFSCatInfoContentMod | kFSCatInfoDataSizes];
        
		while( (filePath = [di nextObjectFullPath]) )
		{
            [delegate listItem: [NSURL fileURLWithPath: filePath] withAttributes: [di fileAttributes] source: self];
            if( [di cacheExhausted] )
                [delegate dataSourceWillRecache: self];
		}
        
       [delegate dataSourceDidReload: self];
	}
	#endif
}


// -----------------------------------------------------------------------------
//  delegate:
//      Accessor for delegate to get messages during reload:.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(id)               delegate
{
    return delegate;
}


// -----------------------------------------------------------------------------
//  setDelegate:
//      Mutator for delegate to get messages during reload:.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)             setDelegate: (id)del
{
    delegate = del;
}


// -----------------------------------------------------------------------------
//  placeholderIconForItem:attributes:
//      Quickly returns a temporary placeholder icon to use for the files
//      until their icons have been loaded. This simply returns generic file
//      and folder icons. We could probably get a tad fancier here and make
//      file packages look like files and not folders, or maybe even do a simple
//      icon resolution based on the suffix/type/creator already.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) testPlaceHolderIconForItemAttributes
{
	UKNotNil([NSImage imageNamed: @"common_Unknown"]);
}

-(NSImage*)         placeholderIconForItem: (NSURL*)url attributes: (NSDictionary*)attrs
{
    #ifdef __ETOILE__
	//return [[NSWorkspace sharedWorkspace] iconForFileType: @""];
	return [NSImage imageNamed: @"common_Unknown"];
	
	#else
	if( [[attrs objectForKey: NSFileType] isEqualToString: NSFileTypeDirectory] )
        return [[UKFileIcon genericFolderIcon] image];
    else
        return [[UKFileIcon genericDocumentIcon] image];
	#endif
}


// -----------------------------------------------------------------------------
//  iconForItem:attributes:
//      Returns the actual icon associated with a file, including any icon
//      preview, custom icon or whatever. This is called from a separate thread,
//      so it isn't dangerous if this is a little slower.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void) testIconForItemAttributes
{
	NSImage *testIcon = [[NSWorkspace sharedWorkspace] iconForFile: folderPath];
	NSSize testSize;
	
	UKNotNil(testIcon);

	testSize = [testIcon size];
	UKTrue(testSize.width >= 16 && testSize.height >= 16);
}

-(NSImage*)         iconForItem: (NSURL*)url attributes: (NSDictionary*)attributes
{
    NSString*       path = [url path];
	NSImage *fileIcon = nil;
	
	#ifdef __ETOILE__
	
	fileIcon = [[NSWorkspace sharedWorkspace] iconForFile: path];
	
	#else
	
    NSString*       suf = [[path pathExtension] lowercaseString];
    NSArray*        types = nil;
    NSSize          iconSize = NSMakeSize(128,128);
    BOOL            hasCustomIcon = !attributes || [[attributes objectForKey: UKItemHasCustomIcon] boolValue];
    
    if( [delegate showIconPreview] )
        types = [NSImage imageFileTypes];
    
    if( types )
        fileIcon = [[NSWorkspace sharedWorkspace] previewImageForFile: path size: iconSize];
    
    // Couldn't generate a preview, although we want icon previews, and no custom icon?
    if( !fileIcon && types && [types containsObject: suf] && (!hasCustomIcon || !attributes) )
    {
        // Load the full file and manually cobble together a preview:
        fileIcon = [[[NSImage alloc] initWithContentsOfFile: path] autorelease];
        fileIcon = [fileIcon scaledImageToFitSize: iconSize];
    }
    
    if( !fileIcon )    // Still no icon?
        fileIcon = [[UKFileIcon iconForFile: path] image];  // Ask Icon Services for an icon.
		
	#endif
	
	return fileIcon;
}

@end

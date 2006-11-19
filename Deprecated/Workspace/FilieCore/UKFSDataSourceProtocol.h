/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFSDataSource.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-12-10  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Protocols:
// -----------------------------------------------------------------------------

/* All objects that add a new source of files to Filie must implement this
    protocol. It basically allows an FSItemViewer to list the files this
    object represents. E.g. if there was an UKFTPDataSource, you'd hand
    it an ftp:// URL and it would list the files on this server.
    
    You basically use this like a UKDirectoryEnumerator. */

@protocol UKFSDataSource

-(id)               initWithURL: (NSURL*)folder;

-(void)             reload: (id)sender;

-(id)               delegate;
-(void)             setDelegate: (id)del;

// Quickly get an icon to show for this item:
-(NSImage*)         placeholderIconForItem: (NSURL*)url attributes: (NSDictionary*)attrs;

// More involved method for getting the correct icon for an item. May take some processing:
-(NSImage*)         iconForItem: (NSURL*)url attributes: (NSDictionary*)attrs;

@end


// Protocol the delegate of a UKFSDataSource must comply to:

@protocol UKFSDataSourceDelegate

-(void)             dataSourceWillReload: (id<UKFSDataSource>)dSource;

-(void)             listItem: (NSURL*)url withAttributes: (NSDictionary*)attrs source: (id<UKFSDataSource>)dSource;
-(void)             dataSourceWillRecache: (id<UKFSDataSource>)dSource;     // There'll be a short delay. Delegate should take the opportunity to update its progress display.

-(void)             dataSourceDidReload: (id<UKFSDataSource>)dSource;

// If the data source supports icon previews, it will use this to ask the delegate whether it should return them as the icons:
-(BOOL)             showIconPreview;

@end

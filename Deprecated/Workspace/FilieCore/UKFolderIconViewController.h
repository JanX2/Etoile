/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderViewer.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL, Modified BSD
    
    REVISIONS:
        2004-04-15  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <EtoileExtensions/EtoileCompatibility.h>
#import <Foundation/Foundation.h>
#import "UKFSItemViewProtocol.h"
#import "UKFSItem.h"
#import "UKFSDataSourceProtocol.h"

#ifndef __ETOILE__
#import "UKNibOwner.h"

#else
#import <EtoileExtensions/UKNibOwner.h>

#endif

@protocol UKTest;

// -----------------------------------------------------------------------------
//  Forwards:
// -----------------------------------------------------------------------------

@class UKDistributedView;
#ifndef __ETOILE__
@class UKKQueue;
#endif
@class UKMainThreadActionQueue;
@class UKPushbackMessenger;
@class UKFolderMetaStorage;


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKFolderIconViewController : NSObject
<UKFSItemView,UKFSItemOwner,UKFSDataSourceDelegate,UKTest>
{
	NSString*						folderPath;         // Path of the folder we're listing.
	NSMutableArray*					fileList;           // List of FSItems for our contents.
	#ifndef __ETOILE__
	UKKQueue*						kqueue;             // Watches whether any of our files have changed (can we share this between viewers so we have only one watcher thread?).
	#endif
	IBOutlet UKDistributedView*		fileListView;       // View that shows our files (icon view).
	NSArray*                        hiddenList;         // Names of files to explicitly hide from view.
    UKMainThreadActionQueue*        reloadIconQueue;    // Queue for reload icon messages in a second thread (FIX ME! uhh.. *main* thread???).
    UKPushbackMessenger*            coalescer;          // Object that coalesces all similar messages it receives within a particular amount of time before sending what's left to this object.
    unsigned int                    progressCount;      // Nesting level of progress indicator.
    NSSize                          iconSize;           // Size for icons in our dist view.
    NSString*                       searchString;       // Search string for filter field.
    BOOL                            hideDotFiles;       // Hide files whose names begin with a period?
    BOOL                            showIconPreviews;   // Show previews instead of icons?
    NSMutableArray*                 forceShowList;      // List of names of files to show even if their names start with a period.
    NSTimeInterval                  progressStarted;    // Start time for output how long a particular progress took (debugging only).
    id<UKFSDataSource,NSObject>     dataSource;         // Object we call upon to actually list the files.
    UKFolderMetaStorage*            filieStore;         // Window and item positions, view options etc.
    int                             keepArrangedMode;   // >= 0 if it's a rearrangeItemsByTag: tag for keeping the items sorted.
    NSMutableArray*                 newItems;           // Here we keep all new items that were added to our folder during loadFolderContents:. Doubles as a "busy loading" flag.
    NSMutableArray*                 finalItems;         // During loadFolderContents:, we move all old items in here that still exist. At the end we swap the lists out.
    int                             lastCheckedIndex;   // Cached index for itemForFile: that allows faster sequential access.
    #ifdef __ETOILE__
    NSMutableDictionary*                locks;
    #endif
}

-(id)			initWithPath: (NSString*)path;
-(id)			initWithURL: (NSURL*)url;

-(void)			setURL: (NSURL*)url;

-(NSString*)	displayName;

-(void)         setSearchString: (NSString*)str;
-(NSString*)    searchString;

-(void)         openSelectedFiles: (id)sender;
-(IBAction)     createNewFolder: (id)sender;
-(IBAction)     changeShowIconPreview: (NSButton*)sender;
-(IBAction)     keepArrangedBy: (NSMenuItem*)sender;
-(IBAction)     rearrangeItemsBy: (NSMenuItem*)sender;
-(void)         rearrangeItemsByTag: (int)idx;
-(IBAction)     changeItemSize: (NSMenuItem*)sender;
-(NSSize)       recalcCellSize;

-(NSString*)	fileStorePath;

-(UKFSItem*)    itemForFile: (NSString*)file;
-(UKFSItem*)    itemForPath: (NSString*)path;
-(void)         loadItemIcon: (UKFSItem*)item;

-(void)         startProgress: (NSString*)statusText;
-(void) startProgress: (NSString*)statusText recordTiming: (BOOL)time;
-(void)         stopProgress;

-(void)         finishCreation;

-(IBAction)	delete: (id)sender;
-(IBAction) loadFolderContents: (id)sender;

// For subclassers:
-(id<UKFSDataSource,NSObject>)  newDataSourceForURL: (NSURL*)url;
-(UKFolderMetaStorage*)         newMetaStorageForURL: (NSURL*)url;

@end

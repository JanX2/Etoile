/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderDataSource.h
    
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
#import "UKFSDataSourceProtocol.h"


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

/* This object lists a folder's contents and tells its delegate about each
    item and its attributes. */

@interface UKFolderDataSource : NSObject <UKFSDataSource>
{
    NSString*                   folderPath;
    id<UKFSDataSourceDelegate>  delegate;
}

@end

/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFileInfoPanel.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-12-09  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <EtoileExtensions/UKNibOwner.h>
#import "UKFileInfoProtocol.h"

@protocol UKTest;


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKFileInfoPanel : UKNibOwner <UKFileInfoProtocol,UKTest>
{
    NSMutableArray*         delegates;
    NSMutableDictionary*    fileAttributes;
    BOOL                    isMultipleSelection;
    IBOutlet NSTableView*   attributesTable;
}

@end

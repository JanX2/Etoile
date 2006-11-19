/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFSItemViewer.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-04-15  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@protocol UKFSItemView

+(id)			viewForItemAtPath: (NSString*)path;
+(id)			viewForItemAtURL: (NSURL*)path;

-(NSString*)	displayName;
-(NSString*)	path;

-(BOOL)			isEqual: (id)other;
-(unsigned)     hash;

@end

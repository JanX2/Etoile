/* =============================================================================
    PROJECT:    Filie
    FILE:       UKMainThreadActionQueue.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-11-23  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKMainThreadActionQueue : NSObject
{
    NSMutableArray*     objectsToMessage;
    SEL                 message;
    BOOL                threadRunning;
    BOOL                newestFirst;        // Execute newest messages first, instead of executing them in order?
}

-(id)   initWithMessage: (SEL)msg;

-(void) addObject: (id)obj;

-(void) setMessage: (SEL)msg;
-(SEL)  message;

@end

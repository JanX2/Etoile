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

@protocol UKTest;

// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKMainThreadActionQueue : NSObject <UKTest>
{
    NSMutableArray*     objectsToMessage;
    SEL                 message;
    BOOL                threadRunning;
    BOOL                newestFirst;        // Execute newest messages first, instead of executing them in order?
    
    #ifdef __ETOILE__
    NSMutableDictionary*                locks;
    #endif
}

-(id)   initWithMessage: (SEL)msg;

-(void) addObject: (id)obj;

-(void) setMessage: (SEL)msg;
-(SEL)  message;

@end

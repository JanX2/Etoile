/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFileInfoMixedValueIndicator.h
    
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

@protocol UKTest;

// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

/* [UKFileInfoMixedValueIndicator indicator] returns a shared placeholder object
    (like [NSNull null]) that you can put in a collection to indicate a "mixed"
    value, i.e. a value that differs between the selected items. This also adds
    a method on NSObject, isDifferentAcrossSelectedItems, which can thus be used
    to query any item in a collection to find out whether it is a real value,
    or mixed.
    Use the indicatorWithString: and indicatorWithInt: methods if you want to
    provide some default values that inspectors can display. E.g. if this is
    a value that is used as the state for a check box, you may want to use
    indicatorWithInt: NSMixedState to indicate the state in the inspector
    without having to specially account for mixed values.
    Similarly, you could provide a string such as @"<multiple items selected>"
    to be displayed in a file name text field. */

@interface UKFileInfoMixedValueIndicator : NSObject <UKTest>
{
    NSString*       stringValue;
    int             intValue;
    float           floatValue;
}

+(id)           indicator;
+(id)           indicatorWithString: (NSString*)str;
+(id)           indicatorWithInt: (int)n;
+(id)           indicatorWithFloat: (float)n;

-(BOOL)         isDifferentAcrossSelectedItems; // Always returns YES.

// Change placeholder value:
-(void)         setStringValue: (NSString*)str; 
-(NSString*)    stringValue; 

-(void)         setIntValue: (int)n; 
-(int)          intValue; 

-(void)         setFloatValue: (float)n; 
-(float)        floatValue; 

-(void)         setBoolValue: (BOOL)n; 
-(BOOL)         boolValue; 

@end


@interface NSObject (UKFileInfoMixedValueIndicator)

-(BOOL) isDifferentAcrossSelectedItems;         // Always returns NO.

@end


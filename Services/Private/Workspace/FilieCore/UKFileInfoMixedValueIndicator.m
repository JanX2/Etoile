/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFileInfoMixedValueIndicator.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-12-09  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFileInfoMixedValueIndicator.h"


@implementation UKFileInfoMixedValueIndicator

// -----------------------------------------------------------------------------
//  indicator:
//      Return the generic shared instance of a mixed value indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

+(id)   indicator       // Shared instance.
{
    static id indy = nil;
    
     if( !indy )
     {
        indy = [[[self class] alloc] init];
        [indy setStringValue: @"*** UKFileInfoMixedValueIndicator ***"];
    }
    
    return indy;
}


// -----------------------------------------------------------------------------
//  indicatorWithString:
//      Return an autoreleased mixed value indicator that represents a certain
//      string. This string can be queried using stringValue.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

+(id)   indicatorWithString: (NSString*)str
{
    UKFileInfoMixedValueIndicator   *indy;
    
    indy = [[[[self class] alloc] init] autorelease];
    [indy setStringValue: str];
    
    return indy;
}


// -----------------------------------------------------------------------------
//  indicatorWithInt:
//      Return an autoreleased mixed value indicator that represents a certain
//      integer. This integer can be queried using intValue.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

+(id)   indicatorWithInt: (int)n
{
    UKFileInfoMixedValueIndicator   *indy;
    
    indy = [[[[self class] alloc] init] autorelease];
    [indy setIntValue: n];
    
    return indy;
}


// -----------------------------------------------------------------------------
//  indicatorWithFloat:
//      Return an autoreleased mixed value indicator that represents a certain
//      float. This float can be queried using floatValue.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

+(id)   indicatorWithFloat: (float)n
{
    UKFileInfoMixedValueIndicator   *indy;
    
    indy = [[[[self class] alloc] init] autorelease];
    [indy setFloatValue: n];
    
    return indy;
}

// -----------------------------------------------------------------------------
//  isDifferentAcrossSelectedItems:
//      All UKFileInfoMixedValueIndicator instances return YES from this
//      method. Our category on NSObject that implements this method returns
//      NO. That way, you can easily detect whether an object is a mixed
//      value when needed.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL) isDifferentAcrossSelectedItems
{
    return YES;
}


// -----------------------------------------------------------------------------
//  setStringValue:
//      Change the string value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         setStringValue: (NSString*)str
{
    if( str != stringValue )
    {
        [stringValue release];
        stringValue = [str retain];
    }
}


// -----------------------------------------------------------------------------
//  stringValue:
//      Retrieve the string value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(NSString*)    stringValue
{
    if( stringValue )
        return stringValue;
    else
        return [NSString stringWithFormat: @"%d", intValue];
}


// -----------------------------------------------------------------------------
//  setIntValue:
//      Change the integer value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         setIntValue: (int)n
{
    intValue = n;
}


// -----------------------------------------------------------------------------
//  intValue:
//      Retrieve the integer value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(int)    intValue
{
    return intValue;
}


// -----------------------------------------------------------------------------
//  setBoolValue:
//      Change the boolean value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         setBoolValue: (BOOL)n
{
    intValue = n;
}


// -----------------------------------------------------------------------------
//  boolValue:
//      Retrieve the boolean value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)    boolValue
{
    return intValue;
}


// -----------------------------------------------------------------------------
//  setFloatValue:
//      Change the decimal number value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         setFloatValue: (float)n
{
    floatValue = n;
}


// -----------------------------------------------------------------------------
//  floatValue:
//      Retrieve the decimal number value of this indicator.
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(float)    floatValue
{
    return floatValue;
}

@end


@implementation NSObject (UKFileInfoMixedValueIndicator)

// -----------------------------------------------------------------------------
//  isDifferentAcrossSelectedItems:
//      Easy way to find out an object *isn't* a mixed value.
//
//      FIX ME! Can we make this a category on NSValue and NSString? Would that
//      be a cleaner implementation? Would that work for NSDate? Urk...
//
//  REVISIONS:
//      2004-12-23  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL) isDifferentAcrossSelectedItems  { return NO; }

@end



#import <Foundation/Foundation.h>

@interface OPMLOutline : NSObject
{
    NSMutableDictionary* attributes;
    NSMutableArray* subOutlines;
    
    id parentElement;
}

// --------------------------------------------
//    initialisers
// --------------------------------------------

+(OPMLOutline*) outline;
+(OPMLOutline*) outlineWithText: (NSString*) aText;
+(OPMLOutline*) outlineWithAttributes: (NSDictionary*) dictionary
                                array: (NSArray*) array;

-(id) init;
-(id) initWithText: (NSString*) aText;

/** Designated initialiser */
-(id) initWithAttributes: (NSDictionary*) dictionary
                   array: (NSArray*) array;


// --------------------------------------------
//    comfortable access
// --------------------------------------------

-(void) setText: (NSString*) aText;
-(NSString*) text;

-(void) setURL: (NSString*) urlString;
-(NSString*) URL;


// --------------------------------------------
//    direct access
// --------------------------------------------

-(NSString*) valueForKey: (NSString*) aKey;
-(void) setValue: (NSString*) aValue
          forKey: (NSString*) aKey;
-(void) deleteValueForKey: (NSString*) aKey;

-(void) setParent: (id) theParent;
-(id) parent;


// --------------------------------------------
//    sub outline access
// --------------------------------------------

-(int) outlineCount;
-(OPMLOutline*) outlineAtIndex: (int) index;
-(void) appendOutline: (OPMLOutline*) anOutline;

@end


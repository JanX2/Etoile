
#import <Foundation/Foundation.h>
#import "OPMLOutline.h"

@interface OPMLDocument : NSObject
{
    // ------------------------
    //    basic OPML attributes
    // ------------------------
    
    NSString* title;
    NSDate* creationDate;
    NSDate* modificationDate;
    NSString* ownerName;
    NSString* ownerEmail;
    
    // ------------------------
    //    miscellaneous
    // ------------------------
    
    BOOL dirty;
    NSMutableArray* topLevelOutlines;
}



// -----------------------------------------------------------
//    Initialisers
// -----------------------------------------------------------

-(id) init;
-(id) initWithData: (NSData*) aData;
+(id) documentWithData: (NSData*) aData;


// -----------------------------------------------------------
//    Accessors for the top level OPML outlines
// -----------------------------------------------------------

-(int) outlineCount;
-(OPMLOutline*) outlineAtIndex: (int) index;
-(void) appendOutline: (OPMLOutline*) anOutline;


// -----------------------------------------------------------
//    Accessors for the OPML attributes
// -----------------------------------------------------------

-(NSString*) title;
-(void) setTitle: (NSString*) aTitle;

/**
 * Returns the creation date of the OPML document.
 * There's no setter for the creation date, as it is
 * set automatically.
 */
-(NSDate*) creationDate;

/**
 * Returns the last modification date of the OPML document.
 * There's no setter for this, as it is set automatically
 * upon writing to the documents.
 */
-(NSDate*) modificationDate;

-(NSString*) ownerName;
-(void) setOwnerName: (NSString*) aName;
-(NSString*) ownerEmail;
-(void) setOwnerEmail: (NSString*) anEmailAddress;


@end


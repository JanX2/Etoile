
#import "OPMLDocument.h"
#import "OPMLParser.h"

@interface OPMLDocument (Private)
-(void) _hasBeenModified;
@end

@implementation OPMLDocument (Private)
-(void) _hasBeenModified
{
    //ASSIGN(modificationDate, [NSDate new]);
    dirty = YES;
}
@end

@implementation OPMLDocument

// -----------------------------------------------------------
//    Initialisers
// -----------------------------------------------------------

-(id) init
{
    if ((self = [super init]) != nil) {
        ASSIGN(self->creationDate, [NSDate new]);
        ASSIGN(self->topLevelOutlines, [NSMutableArray new]);
    }
    
    return self;
}

-(id) initWithData: (NSData*) aData
{
    if ((self = [super init]) != nil) {
        ASSIGN(self->creationDate, [NSDate new]);
        ASSIGN(self->topLevelOutlines, [NSMutableArray new]);
        return [[OPMLParser shared] parseData: aData intoDocument: self];
    }
    
    return self;
}


+(id) documentWithData: (NSData*) aData
{
    return [[self alloc] initWithData: aData];
}


// -----------------------------------------------------------
//    Accessors for the top level OPML outlines
// -----------------------------------------------------------

-(int) outlineCount
{
    return [self->topLevelOutlines count];
}

-(OPMLOutline*) outlineAtIndex: (int) index
{
    return [self->topLevelOutlines objectAtIndex: index];
}

-(void) appendOutline: (OPMLOutline*) anOutline;
{
    if (self->topLevelOutlines == nil) {
        ASSIGN(self->topLevelOutlines, [NSMutableArray new]);
    }
    
    [self->topLevelOutlines addObject: anOutline];
}

// -----------------------------------------------------------
//    Accessors for the OPML attributes
// -----------------------------------------------------------

-(NSString*) title
{
    return self->title;
}

-(void) setTitle: (NSString*) aTitle
{
    ASSIGN(self->title, aTitle);
    [self _hasBeenModified];
}

/**
 * Returns the creation date of the OPML document.
 * There's no setter for the creation date, as it is
 * set automatically.
 */
-(NSDate*) creationDate
{
    NSAssert(self->creationDate != nil, @"creationDate must have a non-nil value");
    
    return self->creationDate;
}

/**
 * Returns the last modification date of the OPML document.
 * There's no setter for this, as it is set automatically
 * upon writing to the documents.
 */
-(NSDate*) modificationDate
{
    if (self->modificationDate) {
        return self->modificationDate;
    } else {
        return [self creationDate];
    }
}

-(NSString*) ownerName
{
    return self->ownerName;
}

-(void) setOwnerName: (NSString*) aName
{
    ASSIGN(self->ownerName, aName);
    [self _hasBeenModified];
}

-(NSString*) ownerEmail
{
    return self->ownerEmail;
}

-(void) setOwnerEmail: (NSString*) anEmailAddress
{
    ASSIGN(self->ownerEmail, anEmailAddress);
    [self _hasBeenModified];
}


@end


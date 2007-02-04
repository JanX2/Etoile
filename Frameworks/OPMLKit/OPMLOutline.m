
#import "OPMLOutline.h"

@interface OPMLOutline (Private)
-(void) _hasBeenModified;
@end

@implementation OPMLOutline (Private)
-(void) _hasBeenModified
{
    // Let the parent know it has been modified, too.
    if (parentElement != nil && [parentElement respondsToSelector: @selector(_hasBeenModified)]) {
        [parentElement _hasBeenModified];
    }
}
@end


@implementation OPMLOutline

// --------------------------------------------
//    initialisers
// --------------------------------------------

+(OPMLOutline*) outline
{
    return [[self alloc] init];
}

+(OPMLOutline*) outlineWithText: (NSString*) aText
{
    return [[self alloc] initWithText: aText];
}

+(OPMLOutline*) outlineWithAttributes: (NSDictionary*) dictionary
                                array: (NSArray*) array
{
    return [[self alloc] initWithAttributes: dictionary array: array];
}

-(id) init
{
    return [self initWithAttributes: [NSDictionary new] array: [NSArray new]];
}

-(id) initWithText: (NSString*) aText
{
    return [self initWithAttributes: [NSDictionary dictionaryWithObject: aText forKey: @"text"]
                              array: [NSArray new]];
}

/** Designated initialiser */
-(id) initWithAttributes: (NSDictionary*) dictionary
                   array: (NSArray*) array
{
    if ((self = [super init]) != nil) {
        ASSIGN(self->attributes, [NSMutableDictionary dictionaryWithDictionary: dictionary]);
        ASSIGN(self->subOutlines, [NSMutableArray arrayWithArray: array]);
    }
    
    return self;
}


// --------------------------------------------
//    comfortable access
// --------------------------------------------

-(void) setText: (NSString*) aText
{
    [self->attributes setObject: aText forKey: @"text"];
    [self _hasBeenModified];
}

-(NSString*) text
{
    return [self->attributes objectForKey: @"text"];
}

-(void) setURL: (NSString*) urlString
{
    [self->attributes setObject: urlString forKey: @"url"];
    [self _hasBeenModified];
}

-(NSString*) URL
{
    return [self->attributes objectForKey: @"url"];
}


// --------------------------------------------
//    direct access
// --------------------------------------------

-(NSString*) valueForKey: (NSString*) aKey
{
    return [self->attributes objectForKey: aKey];
}

-(void) setValue: (NSString*) aValue
          forKey: (NSString*) aKey
{
    [self->attributes setObject: aValue forKey: aKey];
    [self _hasBeenModified];
}

-(void) deleteValueForKey: (NSString*) aKey
{
    [self->attributes removeObjectForKey: aKey];
    [self _hasBeenModified];
}

-(void) setParent: (id) theParent
{
    ASSIGN(self->parentElement, theParent);
    [self _hasBeenModified];
}

-(id) parent
{
    return parentElement;
}

// --------------------------------------------
//    sub outline access
// --------------------------------------------

-(int) outlineCount
{
    return [self->subOutlines count];
}

-(OPMLOutline*) outlineAtIndex: (int) index
{
    return [self->subOutlines objectAtIndex: index];
}

-(void) appendOutline: (OPMLOutline*) anOutline
{
    [self->subOutlines addObject: anOutline];
    [self _hasBeenModified];
}

@end

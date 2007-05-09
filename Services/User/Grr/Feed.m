/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "Feed.h"
#import "Article.h"

#ifdef GNUSTEP
#import "NSURL+Proxy.h"
#endif

// ----------------------------------------------
//    Feed Private interface.
// ----------------------------------------------

@interface Feed (Private)
-(void) beginsFetching;
@end



@implementation Feed

// ----------------------------------------------
//    Counting of unread articles
// ----------------------------------------------

-(int) unreadArticleCount
{
    int i;
    int unreadCount = 0;
    NSArray* articleArray = [[self articleSet] allObjects];
    
    for (i=0; i<[articleArray count]; i++) {
        id<Article> article = [articleArray objectAtIndex: i];
        
        if ([article isRead] == NO) {
            unreadCount ++;
        }
    }
    
    return unreadCount;
}


// ----------------------------------------------
//    Database element protocol
// ----------------------------------------------

-(NSDictionary*) plistDictionary
{
    NSMutableDictionary* dict = [super plistDictionary];
    
    // The DatabaseElement protocol says there has to be a
    // isa key indicating the name of the object's class.
    [dict setObject: [[self class] description] forKey: @"isa"];
    
    // We'll also have to store our database name, if there's
    // a special one.
    if (databaseElementName != nil) {
        [dict setObject: databaseElementName forKey: @"databaseElementName"];
    }
    
    return dict;
}

-(id) initWithDictionary: (NSDictionary*) plistDictionary
{
    if ((self = [super initFromPlistDictionary: plistDictionary]) != nil) {
        ASSIGN(databaseElementName, [plistDictionary objectForKey: @"databaseElementName"]);
    }
    
    return self;
}

-(id<Category>) superElement
{
    return superElem;
}

-(void) setSuperElement: (id<Category>) superElement
{
    ASSIGN(superElem, superElement);
}

-(void) setName: (NSString*) aString
{
    ASSIGN(databaseElementName, aString);
}

-(NSString*) description
{
    if (databaseElementName != nil) {
        return databaseElementName;
    } else {
        return [super description];
    }
}


// ----------------------------------------------
//    Article Group protocol (No manual modifications allowed)
// ----------------------------------------------

-(BOOL) allowsArticleSetDrop: (NSSet*) articleSet
{
    return NO;
}

-(BOOL) dropArticleSet: (NSSet*) articleSet
{
    return NO;
}

-(BOOL) allowsArticleSetRemoval: (NSSet*) articleSet
{
    return NO;
}

-(BOOL) removeArticleSet: (NSSet*) articleSet
{
    return NO;
}


// ----------------------------------------------
//    Overridden fetching methods
// ----------------------------------------------

-(void) fetchInBackground
{
    [self beginsFetching];
    [super fetchInBackground];
}

-(enum RSSFeedError) fetch
{
    [self beginsFetching];
    return [super fetch];
}

@end


// ----------------------------------------------
//    Private methods impl
// ----------------------------------------------
@implementation Feed (Private)

// ----------------------------------------------
//    Gets executed when fetching starts
//    and applies proxy settings if possible
// ----------------------------------------------

-(void) beginsFetching
{
#ifdef GNUSTEP
    [feedURL applyProxySettings];
#endif
}

@end




/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation, in version 2.1
 *  of the License
 * 
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <Foundation/Foundation.h>

#import "RSSFeed+Storage.h"

#import "RSSArticle+Storage.h"



/**
 * The storage methods for storing and restoring feeds.
 */
@implementation RSSFeed (Storage)
/**
 * Returns a Plist-able dictionary representation of this feed.
 */
-(NSDictionary*) plistDictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    [dict setObject: lastRetrieval forKey: @"lastRetrievalDate"];
    [dict setObject: [NSNumber numberWithBool: clearFeedBeforeFetching]
          forKey: @"clearFeedBeforeFetchingFlag"];
    [dict setObject: feedName forKey: @"feedName"];
    [dict setObject: [feedURL description] forKey: @"feedURL"];
    [dict setObject: [articleClass description] forKey: @"articleClass"];
    
    int i;
    NSMutableArray* articleIndex = [NSMutableArray new];
    
    for (i=0; i<[articles count]; i++) {
        [articleIndex addObject: [[articles objectAtIndex: i] url]];
    }
    [dict setObject: articleIndex forKey: @"articleIndex"];
    
    return dict;
}

/**
 * Creates a feed from a suitable Plist-able dictionary representation.
 */
+(id)feedFromPlistDictionary: (NSDictionary*) plistDictionary
{
    return [[[self alloc] initFromPlistDictionary: plistDictionary] autorelease];
}

-(id)initFromPlistDictionary: (NSDictionary*) plistDictionary
{
    if ((self = [super init]) != nil) {
        // This is just an alias (my hands hurt)
        NSDictionary* dict = plistDictionary;
        
        ASSIGN(lastRetrieval, [dict objectForKey: @"lastRetrievalDate"]);
        clearFeedBeforeFetching = [[dict objectForKey: @"clearFeedBeforeFetchingFlag"] boolValue];
        ASSIGN(feedName, [dict objectForKey: @"feedName"]);
        ASSIGN(feedURL, [NSURL URLWithString: [dict objectForKey: @"feedURL"]]);
        ASSIGN(articleClass, NSClassFromString([dict objectForKey: @"articleClass"]));
        
        lastError = RSSFeedErrorNoError;
        status = RSSFeedIsIdle;
        ASSIGN(lock, [NSRecursiveLock new]);
        
        NSArray* articleIndex = [dict objectForKey: @"articleIndex"];
        NSMutableArray* mutArticles = [NSMutableArray new];
        int i;
        for (i=0; i<[articleIndex count]; i++) {
            [mutArticles addObject:
                [articleClass articleFromStorageWithURL: [articleIndex objectAtIndex: i]]];
        }
        
        ASSIGN(articles, [NSArray arrayWithArray: mutArticles]);
    }
    
    return self;
}
@end


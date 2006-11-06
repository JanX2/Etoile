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

#import "RSSLinks.h"
#import "RSSFactory.h"
#import "RSSArticle+Storage.h"
#import <Foundation/Foundation.h>
#import "GNUstep.h"



/*
 * -----------------------------------------------------
 * RSSLink helper methods to serialize this into a Plist
 * -----------------------------------------------------
 */

@interface RSSLink (Storage)
-(NSDictionary*) plistDictionary;
+(id) urlFromPlistDictionary: (NSDictionary*) aDict;
@end

@implementation RSSLink (Storage)
-(NSDictionary*) plistDictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: 3];
    
    NSString* desc = [self description];
    NSString* type = [self fileType];
    NSString* rel  = [self relationType];
    
    if (desc != nil) [dict setObject: desc forKey: @"value"];
    if (type != nil) [dict setObject: type forKey: @"type"];
    if (rel  != nil) [dict setObject: rel  forKey: @"rel"];
    
    return dict;
}

+(id) urlFromPlistDictionary: (NSDictionary*) aDict
{
  return [RSSLink linkWithString: [aDict objectForKey: @"value"]
		  andRel: [aDict objectForKey: @"rel"]
		  andType: [aDict objectForKey: @"type"] ];
}
@end




/**
 * Allows to store articles to files and serialize
 * articles into Plist-compatibly dictionaries.
 */
@implementation RSSArticle (Storage)

/**
 * Returns the article with the URL anURL from the storage
 */
+(id<RSSArticle>)articleFromStorageWithURL: (NSString*) anURL
{
    return [[RSSFactory sharedFactory] articleFromDictionary:
                [NSDictionary dictionaryWithContentsOfFile:
                       [[RSSFactory sharedFactory] storagePathForURL: anURL]]];
}

/**
 * Initialises the article with the URL anURL from the storage.
 * 
 * @deprecated
 * 
 * Calling this method is generally a bad idea, since
 * it doesn't allow you to decide on load-time which
 * article is going to be created. Better use one of the
 * RSSFactory methods for article unarchiving.
 */
-(id) initFromStorageWithURL: (NSString*) anURL
{
#ifdef GNUSTEP
    NSDebugLog(@"Calling -initFromStorageWithURL on a concrete RSSArticle class instance");
#endif
    return [self initWithDictionary:
             [NSDictionary dictionaryWithContentsOfFile:
               [[RSSFactory sharedFactory] storagePathForURL: anURL]]];
}

/**
 * Initialises the article instance with the contents of the aDictionary variable.
 */
-(id) initWithDictionary: (NSDictionary*) aDictionary
{
    if ((self = [super init]) != nil) {
        if (aDictionary == nil) {
            DESTROY(self);
            return self;
        }
        
        ASSIGN( headline,     [aDictionary objectForKey: @"headline"] );
        ASSIGN( url,          [aDictionary objectForKey: @"article URL"] );
        ASSIGN( description,  [aDictionary objectForKey: @"article content"] );
        ASSIGN( date,         [aDictionary objectForKey: @"date"] );
	
	NSArray* arr = [aDictionary objectForKey: @"links"];
	links = [[NSMutableArray alloc] init];
	
	int i;
	for (i=0; i<[arr count]; i++) {
	  [links addObject: [RSSLink urlFromPlistDictionary: [arr objectAtIndex: i]]];
	}
    }
    
    return self;
}

-(NSString*) storagePath
{
    return [[RSSFactory sharedFactory] storagePathForURL: url];
}

/**
 * Stores the article (usually as a file in the Reader folder).
 */
-(BOOL) store
{
    return [[self plistDictionary] writeToFile: [self storagePath] atomically: YES];
}

/**
 * Returns the dictionary that stores the information for this article object.
 */
-(NSDictionary*) plistDictionary
{
    int i;
    NSMutableDictionary* dict;
    NSMutableArray* linksArray;
    
    // Create a (Plist-compatible) array of Dictionaries from
    // the article's link list (an array of NSURL instances)
    linksArray = [NSMutableArray arrayWithCapacity: [links count]];
    for (i=0;i<[links count]; i++) {
        RSSLink* thisURL = [links objectAtIndex: i];
        [linksArray addObject: [thisURL plistDictionary]];
    }
    
    // Create a dictionary from it all.3
    dict = [NSMutableDictionary dictionaryWithCapacity:  10];
    
    if (headline != nil   ) [dict setObject: headline     forKey: @"headline"];
    if (url != nil        ) [dict setObject: url          forKey: @"article URL"];
    if (description != nil) [dict setObject: description  forKey: @"article content"];
    if (date != nil       ) [dict setObject: date         forKey: @"date"];
    
    [dict setObject: linksArray   forKey: @"links"];
    
    return dict;
}

@end



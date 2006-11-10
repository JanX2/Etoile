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

#import <Foundation/NSObject.h>
#import "RSSArticleProtocol.h"

@protocol RSSFactory <NSObject>

/**
 * Creates a feed with the given URL.
 */
- (id<RSSFeed>) feedWithURL: (NSURL*) aURL;

/**
 * Creates and returns an article with the given properties.
 *
 * @param aHeadline the title of the article
 * @param aURL the URL of the article (as a string!)
 * @param aContent the content of the article (as string)
 * @param data the date of creation of that article
 * @return a freshly created article instance (nil on failure)
 */
- (id<RSSArticle>) articleWithHeadline: (NSString*) aHeadline
                                   URL: (NSString*) aURL
                               content: (NSString*) aContent
                                  date: (NSDate*) aDate;

/**
 * Restores the article with the given URL from the hard disk article
 * store.
 */
- (id<RSSArticle>) articleFromStorageWithURL: (NSString*) aURL;

/**
 * Restores the article from that dictionary.
 */
- (id<RSSArticle>) articleFromDictionary: (NSDictionary*) aDictionary;

/**
 * Returns the storage path for a URL.
 */
- (NSString*) storagePathForURL: (NSString*) anURL;

@end

/**
 * A standard implementation of the RSSFactory protocol.
 * This class can easily be subclassed and changed.
 */
@interface RSSFactory : NSObject <RSSFactory>

/**
 * Returns the shared factory instance.
 */
+ (id<RSSFactory>) sharedFactory;

/**
 * Sets another shared factory instance than the currently selected one.
 */
+ (void) setFactory: (id<RSSFactory>) aFactory;


/**
 * Returns the path where an article is stored in based on its URL.
 */
-(NSString*) storagePathForURL: (NSString*) anURL;


- (id<RSSArticle>) articleWithHeadline: (NSString*) aHeadline
                                   URL: (NSString*) aURL
                               content: (NSString*) aContent
                                  date: (NSDate*) aDate;

- (id<RSSArticle>) articleFromStorageWithURL: (NSString*) aURL;

- (id<RSSArticle>) articleFromDictionary: (NSDictionary*) aDictionary;

@end

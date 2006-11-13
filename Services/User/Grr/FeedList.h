/* -*-objc-*-
   
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005 Guenther Noack

   Author: Yen-Ju Chen
   Author: Guenther Noack,,,

   Created: 2005-03-25 21:07:58 +0100 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/Foundation.h>
#import <RSSKit/RSSKit.h>
#import <BookmarkKit/BookmarkKit.h>
#import <CollectionKit/CollectionKit.h>

@interface FeedList : NSObject
{
  BKBookmarkStore *feedStore;
  CKCollection *articleCollection;

  /* list containing RSSFeed objects
   * Key is NSURL from BKBookmark of feedStore.
   * Value is the RSSFeed.
   */
  NSMutableDictionary *list; 
}

+ (FeedList *) feedList;

+ (NSString*) articleCacheLocation;

/* Rebuild feed from bookmark.
 * It does not fetch new articles. */
- (void) buildFeeds;

/* Accessories */
- (BKBookmarkStore *) feedStore;
- (CKCollection *) articleCollection;
- (NSArray*) feeds; /* array of RSSReaderFeed */
- (RSSFeed *) feedForURL: (NSURL *) url; 
- (BKBookmark *) feedBookmarkForURL: (NSURL *) url;
- (CKGroup *) articleGroupForURL: (NSURL *) url; 

/* Add new feed and remove old feed. 
 * If feed is added, it will automatically fetch.
 */
- (void) removeFeed: (RSSFeed *) feed;
- (void) addFeedWithURL: (NSURL *) url;
- (void) addFeedsWithURLs: (NSArray *) urls;
- (void) addFeed: (RSSFeed *) feed;
- (void) addFeeds: (NSArray *) feeds;

/* Update existing feed.
 * This is generally used when feed is fetching in background
 * and return through notification.
 * By updating feed, the article view will be update. */
- (void) updateFeed: (RSSFeed *) feed;

- (void) save;
- (void) removeArticlesOlderThanDay: (int) number;

@end


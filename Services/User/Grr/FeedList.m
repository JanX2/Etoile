/*
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005 Guenther Noack

   Author: Yen-Ju Chen
   Author: Guenther Noack

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


#import <AppKit/AppKit.h>
#import "FeedList.h"
#import "FetchingProgressManager.h"
#import "RSSReaderFeed.h"
#import "Global.h"
#import "GNUstep.h"

static FeedList *feedList = nil;

int articleSortByDate( id articleA, id articleB, void* context )
{
  NSDate* dateA;
  NSDate* dateB;
  int result;
  
  dateA = [articleA date];
  dateB = [articleB date];
  
  if (dateA == nil)
    {
      if (dateB == nil)
	{
	  result = NSOrderedSame;
	}
      else
	{
	  result = NSOrderedDescending;
	}
    }
  else if (dateB == nil)
    {
      result = NSOrderedAscending;
    }
  else
    {
      result = [dateB compare: dateA];
    }
  
  return result;
}


@implementation FeedList

+ (void) initialize
{
  /* Make sure CKItem has right property */
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt: CKStringProperty], kArticleHeadlineProperty,
      [NSNumber numberWithInt: CKStringProperty], kArticleURLProperty,
      [NSNumber numberWithInt: CKStringProperty], kArticleDescriptionProperty,
      [NSNumber numberWithInt: CKDateProperty], kArticleDateProperty,
      [NSNumber numberWithInt: CKIntegerProperty], kArticleReadProperty,
                 nil];
  [CKItem addPropertiesAndTypes: dict];

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt: CKStringProperty], kArticleGroupURLProperty,
                nil];
  [CKGroup addPropertiesAndTypes: dict];
}

+ (FeedList *) feedList;
{
  if (feedList == nil)
    {
      feedList = [[FeedList alloc] init];
    }
  return feedList;
}

+ (NSString *) articleCacheLocation
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  if ([paths count] == 0)
    return nil;

  return [[[paths objectAtIndex: 0] stringByAppendingPathComponent: @"RSSReader"] stringByAppendingPathComponent: @"ArticleCache"];
}

- (id) init
{
  if ((self = [super init]))
    {
      list = [[NSMutableDictionary alloc] init];

      ASSIGN(feedStore, [BKBookmarkStore sharedBookmarkWithDomain: BKRSSBookmarkStore]);
      ASSIGN(articleCollection, AUTORELEASE([[CKCollection alloc] initWithLocation: [FeedList articleCacheLocation]]));

      /* Remove old articles */ 
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      int number = [defaults integerForKey: RSSReaderRemoveArticlesAfterDefaults];
      if (number > 0) {
        ASSIGN(keepDate, [[NSCalendarDate date] dateByAddingYears: 0 
                   months: 0 days: -number hours: 0 minutes: 0 seconds: 0]);
        [self removeArticlesOlderThanDay: keepDate];  
      }

      [self buildFeeds];
    }
  
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(list);
  RELEASE(feedStore);
  RELEASE(articleCollection);
  
  [super dealloc];
}

- (void) buildFeeds
{
  /* Build feeds based on feedStore */
  NSEnumerator *e = [[feedStore items] objectEnumerator];
  BKBookmark *bk;
  while ((bk = [e nextObject])) {
    RSSFeed *feed = [RSSReaderFeed feedWithURL: [bk URL]];
    [feed setAutoClear: YES];
    [list setObject: feed forKey: [bk URL]];
  }
}

- (BKBookmarkStore *) feedStore
{
  return feedStore;
}

- (CKCollection *) articleCollection
{
  return articleCollection;
}

// returns a NSArray, please do *not* change the array, this is
// an internal structure of the class!
- (NSArray*) feeds
{
  return [list allValues];
}

- (RSSFeed *) feedForURL: (NSURL *) url
{
  return [list objectForKey: url];
}

- (BKBookmark *) feedBookmarkForURL: (NSURL *) url
{
  NSEnumerator *e = [[feedStore items] objectEnumerator];
  BKBookmark *bk;
  while ((bk = [e nextObject])) {
    if ([[bk URL] isEqual: url]) {
      return bk;
    }
  }
  return nil;
}

- (CKGroup *) articleGroupForURL: (NSURL *) url
{
  /* Find the right feed */
  NSEnumerator *e = [[articleCollection groups] objectEnumerator];
  CKGroup *group = nil;
  while ((group = [e nextObject])) {
    if ([[group valueForProperty: kArticleGroupURLProperty] isEqualToString: [url absoluteString]])
    {
      return group;
    }
  }
  return nil;
}

- (void) removeFeed: (RSSFeed*) feed
{
  BKBookmark *bk = [self feedBookmarkForURL: [feed feedURL]];
  if (bk) {
    [feedStore removeBookmark: bk];
  }
  [list removeObjectForKey: [feed feedURL]];
}

- (void) addFeedWithURL: (NSURL*) url
{
  [self addFeedsWithURLs: [NSArray arrayWithObject: url]];
}

- (void) addFeedsWithURLs: (NSArray*) urls
{
  NSMutableArray* feedArray;
  int i;
  RSSReaderFeed* feed;
  
  feedArray = [NSMutableArray arrayWithCapacity: [urls count]];
  
  for (i=0; i<[urls count]; i++)
    {
      feed = AUTORELEASE([[RSSReaderFeed alloc]
			   initWithURL: [urls objectAtIndex: i]]);
      
      [feedArray addObject: feed];
    }
  
  [self addFeeds: feedArray];
}

- (void) addFeed: (RSSFeed*) feed
{
  [self addFeeds: [NSArray arrayWithObject: feed]];
}

- (void) addFeeds: (NSArray*) feeds
{
  int i;
  
  // first fetch them
  [[FetchingProgressManager defaultManager] fetchFeeds: feeds];
  
  for (i=0; i<[feeds count]; i++) {
    RSSFeed* feed = (RSSFeed*) [feeds objectAtIndex: i];
    BKBookmark *bk = [BKBookmark bookmarkWithURL: [feed feedURL]];
    [bk setTitle: [[feed feedURL] absoluteString]];
    [list setObject: feed forKey: [feed feedURL]];
    [feedStore addBookmark: bk];
  }
}

- (void) save
{
  [feedStore save];
  [articleCollection save];
}

- (void) removeArticlesOlderThanDay: (NSDate *) date
{
  NSEnumerator *e = [[articleCollection items] objectEnumerator];
  CKItem *item;
  while ((item = [e nextObject])) {
    NSDate *d = [item valueForProperty: kArticleDateProperty];
    if (d) {
      if ([d compare: date] == NSOrderedAscending) {
        RETAIN(item);
        [articleCollection removeRecord: item];
        [[NSNotificationCenter defaultCenter] 
                 postNotificationName: RSSReaderLogNotification
                 object: item];
        DESTROY(item);
      }
    }
  }
}

- (void) updateFeed: (RSSFeed *) feed
{
  /* Need to update name on feedStore */
  BKBookmark *bk = [self feedBookmarkForURL: [feed feedURL]];
  [bk setTitle: [feed feedName]];
  /* Update articleCollection.
   * Remove old articles under this group and add new.
   */
  NSEnumerator *e = [[articleCollection groups] objectEnumerator];
  CKGroup *group = nil;
  CKItem *item = nil;
  BOOL found = NO;
  NSString *URLString = [[feed feedURL] absoluteString];
  while ((group = [e nextObject])) {
    if ([[group valueForProperty: kArticleGroupURLProperty] isEqualToString: URLString])
    {
      found = YES;
      break;
    }
  }

  if (found == NO) {
    /* Feed exist, but no group. Make one */
    group = AUTORELEASE([[CKGroup alloc] init]);
    [articleCollection addRecord: group];
    [group setValue: URLString forProperty: kArticleGroupURLProperty];
  }
  
  e = [feed articleEnumerator];
  RSSArticle *article = nil;
  while ((article = [e nextObject])) {
    /* If older then keepDate, skip it */
    if ((keepDate != nil) && 
        ([[article date] compare: keepDate] == NSOrderedAscending)) {
      continue;
    }

    /* Find existing one */
    BOOL found = NO;
    NSEnumerator *e1 = [[group items] objectEnumerator];
    while ((item = [e1 nextObject])) {
      NSString *headline = [item valueForProperty: kArticleHeadlineProperty];
      NSString *url = [item valueForProperty: kArticleURLProperty];
      if (([headline isEqualToString: [article headline]]) &&
          ([url isEqualToString: [article url]])) 
      {
        found = YES;
      }
    } 
    if (found == NO) {
      /* Add new article */
      item = AUTORELEASE([[CKItem alloc] init]);
      [item setValue: [NSNumber numberWithInt: 0]  /* Unread for new article */
            forProperty: kArticleReadProperty];
      [articleCollection addRecord: item];
      [group addItem: item];
    }
    [item setValue: [article headline] 
          forProperty: kArticleHeadlineProperty];
    [item setValue: [article url] 
          forProperty: kArticleURLProperty];
    [item setValue: [article description] 
          forProperty: kArticleDescriptionProperty];
    [item setValue: [article date] 
          forProperty: kArticleDateProperty];
  }
}

@end

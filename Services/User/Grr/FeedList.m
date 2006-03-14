/*
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

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


#import "FeedList.h"
#import "FeedManagement.h"
#import "FilterManager.h"
#import "RSSReaderFeed.h"
#import "RSSReaderArticle.h"

FeedList* feedList = nil;

FeedList* getFeedList()
{
  if (feedList == nil)
    {
      feedList =
	RETAIN([NSUnarchiver unarchiveObjectWithFile: [FeedList storeFile]]);
      
      if (feedList == nil)
	{
	  feedList = [[FeedList alloc] init];
	}
    }
  
  return feedList;
}


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

+(NSString*)storeDir
{
  return [@"~/GNUstep/Library/RSSReader"
	   stringByExpandingTildeInPath];
}

+(NSString*)storeFile
{
  return [@"~/GNUstep/Library/RSSReader/Serialized"
	   stringByExpandingTildeInPath];
}

-init
{
  if (self = [super init])
    {
      list = [[NSMutableArray alloc] init];
      
      articleListDirty = YES;
      articleList = nil;
      [self buildArticleList];
    }
  
  return self;
}

-(id)initWithCoder: (NSCoder*)coder
{
  if (self = [super init])
    {
      list = RETAIN([coder decodeObject]);
      
      articleListDirty = YES;
      articleList = nil;
      [self buildArticleList];
    }
  
  return self;
}


-(void) dealloc
{
  RELEASE(articleList);
  RELEASE(list);
  
  [super dealloc];
}

-(void)encodeWithCoder: (NSCoder*) coder
{
  [coder encodeObject: list];
}


-(void) buildArticleList
{
  int feedNo, articleNo;
  int feedCount, articleCount;
  NSMutableArray* newArticleList;
  FilterManager* filterManager;
  
  // only proceed if article list is dirty
  if (articleListDirty == NO)
    return;
  
  filterManager = [FilterManager filterManager];
  
  newArticleList = [NSMutableArray array];
  
  feedCount = [list count];
  for (feedNo=0; feedNo<feedCount; feedNo++)
    {
      RSSFeed* feed = [list objectAtIndex: feedNo];
      
      if ([filterManager allowsFeed: feed])
	{
	  NSEnumerator* enumerator;
	  RSSArticle* article;
	  
	  enumerator = [feed articleEnumerator];
	  
	  while( article = [enumerator nextObject] )
	    {
	      if ([filterManager allowsArticle: article])
		{
		  [newArticleList addObject: article];
		}
	    }
	}
    }
  
  
  // articles are sorted here
  RELEASE(articleList);
  articleList =
    [newArticleList sortedArrayUsingFunction: articleSortByDate
	     context: NULL];
  RETAIN(articleList);
  
  
  articleListDirty = NO;
}


// returns a NSArray, please do *not* change the array, this is
// an internal structure of the class!
-(NSArray*) feedList
{
  return AUTORELEASE(RETAIN(list));
}

-(NSArray*) articleList
{
  if (articleListDirty)
    [self buildArticleList];
  
  return AUTORELEASE(RETAIN(articleList));
}


-(void)removeFeed: (RSSFeed*) feed
{
  [list removeObject: feed];
  articleListDirty = YES;
}

-(void)addFeedWithURL: (NSURL*) url
{
  [self addFeedsWithURLs: [NSArray arrayWithObject: url]];
}

-(void)addFeedsWithURLs: (NSArray*) urls
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

-(void)addFeed: (RSSFeed*) feed
{
  [self addFeeds: [NSArray arrayWithObject: feed]];
}

-(void)addFeeds: (NSArray*) feeds
{
  int i;
  BOOL hadErrors;
  
  // we didn't have errors yet.
  hadErrors = NO;
  
  // first fetch them
  [[FetchingProgressManager instance] fetchFeeds: feeds];
  
  for (i=0; i<[feeds count]; i++) {
    RSSFeed* feed = (RSSFeed*) [feeds objectAtIndex: i];
    [list addObject: feed];
  }
  
  [self buildArticleList];
  
  // redraw and reread the feed table
  [[FeedManagement instance] refreshFeedTable];
  
  // redraw and reread the main (article) table
  [getMainController() refreshMainTable];
}

-(BOOL) articleListDirty
{
  return articleListDirty;
}

-(void) setArticleListDirty: (BOOL) isDirty
{
  articleListDirty = isDirty;
}

@end

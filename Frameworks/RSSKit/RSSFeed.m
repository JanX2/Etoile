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

// This needs to have a value to prevent compiler errors on OSX
// #define DEBUG 1
// #define DEBUGX

#import "RSSFeed.h"
#import "RSSFeed+Fetching.h"
#import "GNUstep.h"

//#define DEBUG YES
//#undef DEBUG

@implementation RSSFeed (Private)

-(BOOL) _submitArticles: (NSArray*) newArticles
{
  NSMutableArray* result;
  NSArray* immutableResult;
  int i;
  
  if (newArticles == nil)
    {
      return NO;
    }
  
  if (articles == nil)
    {
      articles = [[NSArray alloc] init];
    }
  
  // The result is first the list of new articles
  result = [[NSMutableArray alloc] initWithArray: newArticles];
  
  for ( i=0; i<[articles count]; i++ )
    {
      RSSArticle* art;
      
      art = [articles objectAtIndex: i];
      [art setFeed: self];
      
      if ([result containsObject: art] == YES)
	{
	  // We need to remove the *new* version of the article
	  // and replace it with the *old* version, since we
	  // want to keep user provided information. (e.g. read/unread)
	  // TODO: In the future, we could use the *new* version
	  //       while merging the user provided info into the new
	  //       article. This would bring us newer versions of
	  //       article texts etc when the feeds are badly
	  //       administrated. (which is usually the case)
	  [result
	    replaceObjectAtIndex: [result indexOfObject: art]
	    withObject: art];
	}
      else
	{
	  [result addObject: art];
	  [_delegate feed: self
		     addedArticle: art];
	}
    }
  
  immutableResult = [[NSArray alloc] initWithArray: result];
  
  RELEASE(result);
  RELEASE(articles);
  articles = immutableResult; // retain count is already 1
  
  return YES;
}
@end

@implementation RSSFeed

+feed
{
  return AUTORELEASE([[self alloc] init]);
}

+feedWithURL: (NSURL*) aURL
{
  return AUTORELEASE([[self alloc] initWithURL: aURL]);
}

-init
{
  return [self initWithURL: nil];
}


/**
 * Designated initializer
 */
-initWithURL: (NSURL*) aURL
{
  [super init];
  
#ifdef DEBUG
  NSLog(@"(newFeed) initWithURL: %@", aURL);
#endif
  
  feedURL = RETAIN(aURL);
  articles = [[NSArray alloc] init];
  lastRetrieval = RETAIN([NSDate dateWithTimeIntervalSince1970: 0.0]);
  clearFeedBeforeFetching = YES;
  lastError = RSSFeedErrorNoError;
  feedName = nil;
  articleClass = [RSSArticle class];
  
  status = RSSFeedIsIdle;
  
  return self;
}

- (void) dealloc
{
  DESTROY(cacheData);
  [super dealloc];
}


-(NSString*) description
{
  return [self feedName];
}



// access to the status
- (enum RSSFeedStatus) status
{
  return status;
}


- (BOOL) isFetching
{
    return (status == RSSFeedIsFetching) ? YES : NO;
}


-(void)setDelegate: (id<RSSFeedDelegate>)aDelegate
{
  ASSIGN(_delegate, aDelegate);
}

-(id<RSSFeedDelegate>)delegate
{
  return AUTORELEASE(RETAIN(_delegate));
}



/**
 * Implementation of the NewRSSArticleListener interface.
 */
-(void) newArticleFound: (id<RSSArticle>) anArticle
{
  // XXX: inefficient solution!
  [self _submitArticles:[NSArray arrayWithObjects: anArticle, NULL]];
}



// access to the articles


- (NSEnumerator*) articleEnumerator
{
  NSEnumerator* result;
  
#ifdef DEBUG
  NSLog(@"%@ -articleEnumerator", self);
#endif
  
  result = AUTORELEASE(RETAIN([articles objectEnumerator]));
  return result;
}


- (RSSArticle*) articleAtIndex: (int) index
{
  RSSArticle* a;
  
  NSLog(@"articleAtIndex: is deprecated!");
  
  if (index >= [articles count])
    {
      return nil;
    }
  
  a = [articles objectAtIndex: index];
  
  return a;
}

- (unsigned int) count
{
  NSLog(@"FIXME: -count is deprecated on RSSFeed objects");
  return [articles count];
}


- (void) removeArticle: (RSSArticle*) article
{
  NSMutableArray* result;
  NSArray* immutableResult;
  
#ifdef DEBUG
  NSLog(@"%@ -removeArticle: %@", self, article);
#endif
  
  result = [[NSMutableArray alloc] initWithArray: articles];
  [result removeObject: article];
  immutableResult = [[NSArray alloc] initWithArray: result];
  RELEASE(articles);
  RELEASE(result);
  articles = immutableResult;
  // immutableResult has a retain count of 1
}



// preferences

/**
 * Sets the feed name
 */
- (void) setFeedName: (NSString*) aFeedName
{
    ASSIGN(feedName, aFeedName);
}


- (NSString*) feedName
{
#ifdef DEBUG
  NSLog(@"<feed instance> -feedName", self);
#endif
  if (feedName == nil)
    {
      return @"Unnamed feed";
    }
  else
    {
      return AUTORELEASE(RETAIN(feedName));
    }
}

- (NSURL*) feedURL
{
#ifdef DEBUG
  NSLog(@"%@ -feedURL", self);
#endif
  
  if (feedURL == nil)
    {
      return nil;
    }
  else
    {
      return AUTORELEASE(RETAIN(feedURL));
    }
}

// Equality and hash codes
- (unsigned) hash
{
  return [feedURL hash];
}

- (BOOL) isEqual: (id)anObject
{
  return [feedURL isEqual: [anObject feedURL]];
}


// Sets the automatic clearing of the feed.
- (void) setAutoClear: (BOOL) autoClear
{
  clearFeedBeforeFetching = autoClear;
}

- (BOOL) autoClear;
{
  return clearFeedBeforeFetching;
}

/**
 * Clears the article list.
 * NOT SYNCHRONIZED!
 */
- (void) clearArticles
{
  // Delete and recreate the list of articles.
  RELEASE(articles);
  articles = [[NSArray alloc] init];
  lastRetrieval = RETAIN([NSDate dateWithTimeIntervalSince1970: 0.0]);
}


-(void) setArticleClass:(Class)aClass
{
#ifdef DEBUG
  NSLog(@"%@ -setArticleClass: %@", self, aClass);
#endif
  
  if ([aClass isSubclassOfClass: [RSSArticle class]])
    {
      articleClass = aClass;
    }
}

/**
 * Returns the class of the article objects. This needs to be a subclass
 * of RSSArticle. (Also needed to implement the NewRSSArticleListener
 * class)
 *
 * @return the article class
 */
-(Class) articleClass
{
  return articleClass;
}


-(NSDate*) lastRetrieval
{
  return AUTORELEASE(RETAIN(lastRetrieval));
}

@end


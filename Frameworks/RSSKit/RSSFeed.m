
// This needs to have a value to prevent compiler errors on OSX
// #define DEBUG 1
// #define DEBUGX

#import "RSSFeed.h"
#import "FeedFetching.h"
#import "GNUstep.h"

//#define DEBUG YES
//#undef DEBUG

@implementation RSSFeed (Private)
/**
 * NOT SYNCHRONIZED!
 * @deprecated
 */
-(BOOL) _submitArticle: (RSSArticle*) anArticle
{
  NSMutableArray* result;
  BOOL success = YES;
  
  NSLog(@"_submitArticle: is deprecated");
  
  
  if (anArticle == nil)
    return NO;
  
  if (articles == nil)
    {
      articles = [[NSArray alloc] init];
    }
  
  [lock lock];
  
  result = [[NSMutableArray alloc] initWithArray: articles];
  
  
  if ([result containsObject: anArticle] == NO)
    {
      [result addObject: anArticle];
      RELEASE(articles);
      articles = [[NSArray alloc] initWithArray: result];
      success = YES;
    }
  else
    {
      // XXX: Aren't we successful in this case?
      success = NO;
    }
  
  [lock unlock];
  
  RELEASE(result);
  
  return success;
}



-(BOOL) _submitArticles: (NSArray*) newArticles
{
  NSMutableArray* result;
  NSArray* immutableResult;
  int i;
  
  [lock lock];
  
  if (newArticles == nil)
    {
      [lock unlock];
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
	}
    }
  
  immutableResult = [[NSArray alloc] initWithArray: result];
  
  RELEASE(result);
  RELEASE(articles);
  articles = immutableResult; // retain count is already 1
  
  [lock unlock];
  
  return YES;
}
@end

@implementation RSSFeed


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
  
  lock = [[NSRecursiveLock alloc] init];
  status = RSSFeedIsIdle;
  
  return self;
}


-(NSString*) description
{
  return [self feedName];
}




// New encoding numbers start with 50, every value below
// 50 must be in the old encoding format and thus represent
// the error number. (I didn't think of those versions yet,
// at that time... :-/)

#define NEW_ENCODING_NUMBER    50
#define OLD_ENCODING(encoding) ((encoding)<NEW_ENCODING_NUMBER)

#define ENCODING_VERSION_05DEVEL NEW_ENCODING_NUMBER



-(id)initWithCoder: (NSCoder*)coder
{
  int i;
  int encodingVersion;
  
#ifdef DEBUG
  NSLog(@"started decoding RSSFeed");
#endif
  
  if ((self = [self init]))
    {
      RELEASE(articles);
      RELEASE(feedName);
      
      // It's really ugly to have this standing here, but there's
      // no other way to do it without breaking backwards compatibility.
      // The format will definitely always begin with a article array.
      articles = RETAIN([coder decodeObject]);
      
      [coder decodeValueOfObjCType:@encode(int) at:&encodingVersion];
      
      switch (encodingVersion)
	{
	case ENCODING_VERSION_05DEVEL:
	  // This is the format introduced with the 0.5 development
	  // version on May 27, 2005.
	  [coder decodeValueOfObjCType:@encode(int) at:&lastError];
	  [coder decodeValueOfObjCType:@encode(BOOL)
		 at:&clearFeedBeforeFetching];
	  feedName = RETAIN([coder decodeObject]);
	  feedURL = RETAIN([coder decodeObject]);
	  lastRetrieval = RETAIN([coder decodeObject]);
	  break;
	  
	default:
	  // This is the original format. I didn't think of using version
	  // numbers back then. Then it had the last Error value at that
	  // place. Now we already have read this value.
	  // It's in encodingVersion. :-/
	  // [coder decodeValueOfObjCType:@encode(int) at:&lastError];
	  lastError = encodingVersion;
	  [coder decodeValueOfObjCType:@encode(BOOL)
		 at:&clearFeedBeforeFetching];
	  feedName = RETAIN([coder decodeObject]);
	  feedURL = RETAIN([coder decodeObject]);
	  break;
	}
      
      // finally, set the feed attribute of the articles to 'self'
      for (i=0; i<[articles count]; i++)
	{
	  RSSArticle* article;
	  
	  article = [articles objectAtIndex: i];
	  
	  [article feed: self];
	}
    }
  
  lock = [[NSRecursiveLock alloc] init];
  status = RSSFeedIsIdle;
  
#ifdef DEBUG
  NSLog(@"finished decoding RSSFeed (rc=%d)", [self retainCount]);
#endif
  
  return self;
}

-(void)encodeWithCoder: (NSCoder*)coder
{
  int encodingVersion = ENCODING_VERSION_05DEVEL;
  
#ifdef DEBUG
  NSLog(@"started encoding RSSFeed");
#endif
  
  // This is the format introduced with the 0.5 development version
  // on May 27, 2005.
  [coder encodeObject: articles];
  [coder encodeValueOfObjCType: @encode(int) at:&encodingVersion];
  [coder encodeValueOfObjCType: @encode(int) at:&lastError];
  [coder encodeValueOfObjCType: @encode(BOOL)
	 at:&clearFeedBeforeFetching];
  [coder encodeObject: feedName];
  [coder encodeObject: feedURL];
  [coder encodeObject: lastRetrieval];
  
#ifdef DEBUG
  NSLog(@"finished encoding RSSFeed");
#endif
}


// access to the status
- (enum RSSFeedStatus) status
{
  return status;
}




// access to the articles


- (NSEnumerator*) articleEnumerator
{
  NSEnumerator* result;
  
#ifdef DEBUG
  NSLog(@"%@ -articleEnumerator", self);
#endif
  
  [lock lock];
  result = AUTORELEASE(RETAIN([articles objectEnumerator]));
  [lock unlock];
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
  
  [lock lock];
  
  result = [[NSMutableArray alloc] initWithArray: articles];
  [result removeObject: article];
  immutableResult = [[NSArray alloc] initWithArray: result];
  RELEASE(articles);
  RELEASE(result);
  articles = immutableResult;
  // immutableResult has a retain count of 1
  
  [lock unlock];
}



// preferences
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
 * Returns the class of the article objects. This will be a subtype
 * of RSSArticle.
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


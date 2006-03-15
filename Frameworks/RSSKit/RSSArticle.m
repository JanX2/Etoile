
// -*-objc-*-

// #define DEBUG 1

#import "RSSArticle.h"
#import "GNUstep.h"

@implementation RSSArticle


// methods to come... FIXME
-init
{
  return [self initWithHeadline: @"no headline"
	       url: @"no URL"
	       description: @"no description"
	       time: 0 ];
}


-initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     date: (NSDate*)   myDate
{
  [super init];
  
  headline =      RETAIN(myHeadline);
  url =           RETAIN(myUrl);
  description =   RETAIN(myDescription);
  date =          RETAIN(myDate);
  feed =          nil; // non-retained, too.
  links =         nil;
  
  return self;
}


-initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     time: (unsigned int) myTime
{
  return
    [self initWithHeadline: myHeadline
	  url: myUrl
	  description: myDescription
	  date: [NSDate dateWithTimeIntervalSince1970: ((double)myTime)]
     ];
}


-(void) dealloc
{
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc started");
#endif
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc headline has %i", [headline retainCount]);
#endif
  RELEASE(headline);
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc url has %i", [url retainCount]);
#endif
  RELEASE(url);
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc desc has %i", [description retainCount]);
#endif
  RELEASE(description);
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc date has %i", [date retainCount]);
#endif
  RELEASE(date);
#ifdef DEBUG
  NSLog(@"RSSArticle dealloc finished");
#endif
  
  RELEASE(links);
  
  [super dealloc];
}


#define ENCODING_VERSION 1

-(id)initWithCoder: (NSCoder*)coder
{
#ifdef DEBUG
  NSLog(@"started decoding RSSArticle");
#endif
  
  if ((self = [super init]))
  {
    unsigned int version = 0;
    
    [coder decodeValueOfObjCType: @encode(unsigned int) at: &version];
    
    switch (version)
      {
      case 0:
	date =          RETAIN([coder decodeObject]);
	headline =      RETAIN([coder decodeObject]);
	url =           RETAIN([coder decodeObject]);
	description =   RETAIN([coder decodeObject]);
	links =         nil;
	break;
	
      case 1:
	date =          RETAIN([coder decodeObject]);
	headline =      RETAIN([coder decodeObject]);
	url =           RETAIN([coder decodeObject]);
	description =   RETAIN([coder decodeObject]);
	links =         RETAIN([coder decodeObject]);
	break;
	
      default:
	NSLog(@"FATAL: Unknown RSSArticle version %d, please upgrade!",
	      version);
	break;
      }
  }
  
#ifdef DEBUG
  if (self != nil)
    NSLog(@"finished decoding RSSArticle (rc=%i)", [self retainCount]);
  else
    NSLog(@"finished decoding RSSArticle (self is nil!)");
#endif
  
  return self;
}


-(void)encodeWithCoder: (NSCoder*)coder
{
  unsigned int version = ENCODING_VERSION;
  
  [coder encodeValueOfObjCType: @encode(unsigned int) at: &version];
  [coder encodeObject: date];
  [coder encodeObject: headline];
  [coder encodeObject: url];
  [coder encodeObject: description];
  [coder encodeObject: links];
}



-(NSString*)headline
{
  return AUTORELEASE(RETAIN(headline));
}

-(NSString*)url
{
  return AUTORELEASE(RETAIN(url));
}

-(NSString*)description
{
  return AUTORELEASE(RETAIN(description));
}

-(NSDate*) date
{
  return AUTORELEASE(RETAIN(date));
}

-(void)feed:(RSSFeed*)aFeed
{
  // Feed is NON-RETAINED!
  feed = aFeed;
}

-(RSSFeed*)feed
{
  // Feed is NON-RETAINED!
  return feed;
}


-(void)setLinks:(NSMutableArray*) someLinks
{
  RELEASE(links);
  links = RETAIN(someLinks);
}


-(void)addLink:(NSURL*) anURL
{
  if (anURL == nil)
    return;
  
  if (links == nil)
    {
      links = [NSMutableArray arrayWithObject: anURL];
    }
  else
    {
      [links addObject: anURL];
    }
}


-(NSArray*)links
{
  return AUTORELEASE(RETAIN(links));
}



// Equality and hash codes
- (unsigned) hash
{
  return [headline hash] ^ [url hash];
}


/**
 * RSS Articles are equal if both the article headlines
 * and the article URLs are equal. If they are equal is
 * tested by calling the isEqual: method on those.
 */
- (BOOL) isEqual: (id)anObject
{
  if ( ( [headline isEqualToString: [anObject headline]] == YES ) &&
       ( [url      isEqualToString: [anObject url]]      == YES ) )
    {
      return YES;
    }
  else
    {
      return NO;
    }
}


@end


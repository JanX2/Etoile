/*
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,

   Created: 2005-05-27 20:15:06 +0000 by guenther

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

#import "RSSReaderFeed.h"
#import "RSSReaderArticle.h"

@implementation RSSFeed (Subclassing)

-(BOOL) isSubclassedFeed
{
  return NO;
}

@end

// --------------------------------------------

@implementation RSSReaderFeed (Subclassing)

-(BOOL) isSubclassedFeed
{
  return YES;
}

@end

// --------------------------------------------

@implementation RSSReaderFeed

-(id)initWithURL: (NSURL*) aURL
{
  if ((self = [super initWithURL: aURL]))
    {
      // half an hour
      [self setMinimumUpdateInterval: (NSTimeInterval)(1800.0)];
    }
  
  [self setArticleClass: [RSSReaderArticle class]];
  return self;
}

-(id)initWithCoder: (NSCoder*)coder
{
  if ((self = [super initWithCoder: coder]))
    {
      int encodingVersion;
      
      [coder decodeValueOfObjCType: @encode(int)
	     at: &encodingVersion];
      
      switch (encodingVersion)
	{
	case 1: // version 0.5pre2 (1)
	  [coder decodeValueOfObjCType: @encode(NSTimeInterval)
		 at: &minUpdateInterval];
	  break;
	  
	default:
	  NSLog(@"Fatal: no encoding version for RSSReaderFeed");
	  break;
	}
    }
  
  [self setArticleClass: [RSSReaderArticle class]];
  return self;
}

-(void)encodeWithCoder: (NSCoder*)coder
{
  int encodingVersion = 1;
  
  [super encodeWithCoder: coder];
  
  [coder encodeValueOfObjCType: @encode(int) at: &encodingVersion];
  [coder encodeValueOfObjCType: @encode(NSTimeInterval)
	 at: &minUpdateInterval];
}

-(void) setMinimumUpdateInterval: (NSTimeInterval) aTimeInterval
{
  minUpdateInterval = aTimeInterval;
}

-(NSTimeInterval) minimumUpdateInterval
{
  return minUpdateInterval;
}

-(BOOL) needsRefresh
{
  // .oO( [lastRetrieval timeIntervalSinceNow] returns a negative value )
  if (-[[self lastRetrieval] timeIntervalSinceNow] > minUpdateInterval)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

-(BOOL) setURLString: (NSString*) aUrlString
{
  NSURL* url;
  
  url = [NSURL URLWithString: aUrlString];
  
  if (url == nil)
    {
      return NO;
    }
  
  RELEASE(feedURL);
  feedURL = RETAIN(url);
  return YES;
}


/**
 * Override the fetch method from the RSSFeed class to let
 * Grr do the HTTP request in a separate thread. :-)
 */
-(enum RSSFeedError) fetch
{
    status = RSSFeedIsFetching;
    [NSThread detachNewThreadSelector: @selector(threadedFetch:)
                             toTarget: self
                           withObject: feedURL];
}

/**
 * Runs in a worker thread only
 */
-(void) threadedFetch: (NSURL*) myURL
{
    NSAutoreleasePool* threadAutoreleasePool =
        [[NSAutoreleasePool alloc] init];
    
    NSData* data = [self fetchDataFromURL: myURL];
    
    [self performSelectorOnMainThread: @selector(fetchWithData:)
                           withObject: data
                        waitUntilDone: NO];
    
    [threadAutoreleasePool release];
    [NSThread exit];
}

@end


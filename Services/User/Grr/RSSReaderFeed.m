/*
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005 Guenther Noack

   Author: Yen-Ju Chen
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
#import "GNUstep.h"

@implementation RSSReaderFeed

- (id) initWithURL: (NSURL*) aURL
{
  if ((self = [super initWithURL: aURL]))
    {
      // half an hour
      [self setMinimumUpdateInterval: (NSTimeInterval)(1800.0)];
    }
  
  [self setArticleClass: [RSSArticle class]];
  return self;
}

- (void) setMinimumUpdateInterval: (NSTimeInterval) aTimeInterval
{
  minUpdateInterval = aTimeInterval;
}

- (NSTimeInterval) minimumUpdateInterval
{
  return minUpdateInterval;
}

- (BOOL) needsRefresh
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

- (BOOL) setURLString: (NSString*) aUrlString
{
  NSURL *url = [NSURL URLWithString: aUrlString];
  
  if (url == nil)
    {
      return NO;
    }
  
  ASSIGN(feedURL, url);
  return YES;
}

-(enum RSSFeedError) fetchWithData: (NSData*)data
{
//  [data writeToFile: @"/tmp/grr_data" atomically: YES];
  int result = [super fetchWithData: data];
  return result;
}

@end


/* -*-objc-*-
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005 Guenther Noack

   Author: Yen-Ju Chen
   Author: Guenther Noack,,,

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

#import <RSSKit/RSSFeed.h>
#import <Foundation/Foundation.h>

@interface RSSReaderFeed : RSSFeed
{
@private
  NSTimeInterval minUpdateInterval;
}

/**
 * Sets the minimum update interval for a feed.
 * Many website administrators are concerned about
 * the load RSS Readers cause to their servers. So
 * I consider it to be good behaviour to have a
 * minimum update interval, so that it is ensured
 * feeds aren't fetched too often.
 */
- (void) setMinimumUpdateInterval: (NSTimeInterval) aTimeInterval;

/**
 * Returns the minimal update interval.
 * @return Minimal update interval as NSTimeInterval
 */
- (NSTimeInterval) minimumUpdateInterval;

/**
 * Returns YES if and only if the feed needs a refresh.
 * This is the case when the minimum feed fetching time interval
 * is smaller than the time interval since the last fetch.
 */
- (BOOL) needsRefresh;

/**
 * Sets the URL of the feed to a new value.
 * @param aUrlString a String, which represents the URL.
 * @return YES if and only if the string was a valid URL and could be used
 */
- (BOOL) setURLString: (NSString*) aUrlString;

@end


/** <title>ETNewsFeed.h</title>
 
	<abstract></abstract>
	
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  09-09-13
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <RSSKit/RSSKit.h>

@interface ETNewsFeed : NSObject <ETCollection, ETPropertyValueCoding>
{
	NSMutableDictionary *_properties;
	RSSFeed *_feed;
	NSMutableArray *_articles;
}

@end

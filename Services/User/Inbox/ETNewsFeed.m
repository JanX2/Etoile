/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  09-09-13
 License: Modified BSD (see COPYING)
 */

#import "ETNewsFeed.h"
#import "ETNewsArticle.h"

@implementation ETNewsFeed

- (id) init
{
	SUPERINIT;
	_properties = [[NSMutableDictionary alloc] init];
	_articles = [[NSMutableArray alloc] init];
	return self;
}

- (NSString *)displayName
{
	return [NSString stringWithFormat: @"News Feed %@",
			[_properties valueForKey: @"URL"]];
}

DEALLOC(DESTROY(_properties);)

- (void) fetch
{
	[_feed release];
	_feed = [RSSFeed feedWithURL:
			 [NSURL URLWithString: [self valueForProperty: @"URL"]]];
	NSLog(@"Asked to fetch rss for %@.", _feed);

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(fetched:)
												 name: RSSFeedFetchedNotification
											   object: _feed];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(fetchFailed:)
												 name: RSSFeedFetchFailedNotification
											   object: _feed];
	
	[_feed fetchInBackground];	
}

- (void) fetched: (NSNotification *)notif
{
	NSLog(@"RSS Fetch complete.");
	
	NSEnumerator *enumerator = [_feed articleEnumerator];
	FOREACHE(nil, article, RSSArticle *, enumerator)
	{
		NSLog(@"Add article %@, name %@", article, [article headline]);
		[_articles addObject: [ETNewsArticle articleWithRSSArticle: article]];
	}
	
	[[NSApp delegate] reload];
}

- (void) fetchFailed: (NSNotification *)notif
{
	NSLog(@"RSS Fetch fail :(.");
}

/* ETPropertyValueCoding */

- (NSArray *) properties
{
	return [A(@"URL") arrayByAddingObjectsFromArray: [super properties]];
}
- (id) valueForProperty: (NSString *)key
{
	if ([A(@"URL") containsObject: key])
	{
		return [_properties valueForKey: key];
	}
	else
	{
		return [super valueForProperty: key];
	}
}
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	if ([A(@"URL") containsObject: key])
	{
		[_properties setValue: value forKey: key];
		[self fetch];
		return YES;
	}
	else
	{
		return [super setValue: value forProperty: key];
	}
}



/* ETCollection */

- (BOOL) isOrdered
{
	return YES;
}
- (BOOL) isEmpty
{
	return [_articles count] == 0;
}
- (id) content
{
	return _articles;
}
- (NSArray *) contentArray
{
	return [self content];
}
- (NSEnumerator *) objectEnumerator
{
	return [_articles objectEnumerator];
}
- (unsigned int) count
{
	return [_articles count];
}

@end

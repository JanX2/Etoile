/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  09-09-13
 License: Modified BSD (see COPYING)
 */

#import "ETNewsArticle.h"


@implementation ETNewsArticle

+ (ETNewsArticle *)articleWithRSSArticle: (RSSArticle *)article
{
	return [[[ETNewsArticle alloc] initWithRSSArticle: article] autorelease];
}

- (id)initWithRSSArticle: (RSSArticle *)article
{
	SUPERINIT;
	ASSIGN(_article, article);
	return self;
}

- (NSString *)displayName
{
	return [_article headline];
}

@end

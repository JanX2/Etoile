/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.
*/

#import "ArticleFactory.h"
#import "Feed.h"

@implementation ArticleFactory

- (id<Feed>) feedWithURL: (NSURL*) aURL
{
    id<Feed> feed = (id<Feed>) [Feed feedWithURL: aURL];
    [feed setAutoClear: NO];
    
    return feed;
}

- (id<Article>) articleWithHeadline: (NSString*) aHeadline
                                URL: (NSString*) aURL
                            content: (NSString*) aContent
                               date: (NSDate*) aDate
{
    id <Article> article = [[Article alloc] initWithHeadline: aHeadline
                                                         url: aURL
                                                 description: aContent
                                                        date: aDate];
    return [article autorelease];
}

- (id<Article>) articleFromDictionary: (NSDictionary*) aDictionary
{
    // TODO: Create lazy-loading-proxy objects here!
    return [[[Article alloc] initWithDictionary: aDictionary] autorelease];
}


@end

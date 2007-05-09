/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSObject.h>
#import <RSSKit/RSSFactory.h>
#import "Article.h"

@interface ArticleFactory : RSSFactory

- (id<RSSArticle>) articleWithHeadline: (NSString*) aHeadline
                                   URL: (NSString*) aURL
                               content: (NSString*) aContent
                                  date: (NSDate*) aDate;

- (id<RSSArticle>) articleFromDictionary: (NSDictionary*) aDictionary;

@end

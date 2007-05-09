/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <RSSKit/RSSKit.h>
#import <RSSKit/RSSFeed+Storage.h>

#import "ArticleGroup.h"


@protocol Feed <RSSFeed,ArticleGroup>
-(int) unreadArticleCount;
@end

@interface Feed : RSSFeed <Feed>
{
    id<Category> superElem;
    NSString* databaseElementName;
}

@end


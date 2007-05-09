/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>

#import "DatabaseElement.h"

extern NSString* ArticleGroupChangedNotification;

@protocol ArticleGroup <DatabaseElement>
/**
 * Returns a set of all articles contained in this group.
 */
-(NSSet*) articleSet;

/**
 * Returns YES if and only if dropping of the articles in
 * articleSet is allowed into this article group.
 *
 * article set is a set of objects conforming to the
 * Article protocol.
 */
-(BOOL) allowsArticleSetDrop: (NSSet*) articleSet;

/**
 * Drops the article set into the article group. If the
 * operation fails, NO is returned.
 */
-(BOOL) dropArticleSet: (NSSet*) articleSet;

/**
 * Returns YES if and only if this article set can be manually
 * removed from the article group.
 */
-(BOOL) allowsArticleSetRemoval: (NSSet*) articleSet;

/**
 * Removes the given article set from the article group and
 * returns YES on success.
 */
-(BOOL) removeArticleSet: (NSSet*) articleSet;
@end

@interface ArticleGroup : NSObject <ArticleGroup>
{
    NSMutableSet* articleSet;
}

@end



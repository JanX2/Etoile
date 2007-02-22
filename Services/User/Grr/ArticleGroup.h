/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
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



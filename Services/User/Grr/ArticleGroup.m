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

#import "ArticleGroup.h"

NSString* ArticleGroupChangedNotification = @"ArticleGroupChangedNotification";

@implementation ArticleGroup

// ----------------------------------------------------------
//    initialisation
// ----------------------------------------------------------

-(id) init
{
    if ((self = [super init]) != nil) {
        ASSIGN(self->articleSet, [NSMutableSet new]);
    }
    
    return self;
}

// ----------------------------------------------------------
//    basic article group protocol
// ----------------------------------------------------------

/**
 * Returns a set of all articles contained in this group.
 */
-(NSSet*) articleSet
{
    return [NSSet setWithSet: self->articleSet];
}

/**
 * Returns YES if and only if dropping of the articles in
 * articleSet is allowed into this article group.
 *
 * article set is a set of objects conforming to the
 * Article protocol.
 */
-(BOOL) allowsArticleSetDrop: (NSSet*) articleSet
{
    return YES;
}

/**
 * Drops the article set into the article group. If the
 * operation fails, NO is returned.
 */
-(BOOL) dropArticleSet: (NSSet*) articleSet
{
    [self->articleSet unionSet: articleSet];
    [self sendChangedNotification];
}

/**
 * Returns YES if and only if this article set can be manually
 * removed from the article group.
 */
-(BOOL) allowsArticleSetRemoval: (NSSet*) articleSet
{
    return NO;
}

/**
 * Removes the given article set from the article group and
 * returns YES on success.
 */
-(BOOL) removeArticleSet: (NSSet*) articleSet
{
    // TODO: Implement this (don't forget to change the allows~ method, too)
    return NO;
}


// ----------------------------------------------------------
//    sending notifications
// ----------------------------------------------------------

-(void) sendChangedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName: ArticleGroupChangedNotification
                                                        object: self];
}

@end



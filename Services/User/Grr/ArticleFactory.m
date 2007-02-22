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

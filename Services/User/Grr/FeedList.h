/* -*-objc-*-
   
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,,,

   Created: 2005-03-25 21:07:58 +0100 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _FEEDLIST_H_
#define _FEEDLIST_H_

#import <Foundation/Foundation.h>
#import <RSSKit/RSSKit.h>

#import "MainController.h"


@interface FeedList : NSObject <NSCoding>
{
  // list containing RSSFeed objects
  NSMutableArray* list;
  
  // article list dirty?
  BOOL articleListDirty;
  
  // the RSSArticle list which is actually viewed in the main window
  NSArray* articleList;
}

+(NSString*)storeDir;
+(NSString*)storeFile;

-(id)init;
-(id)initWithCoder: (NSCoder*)coder;
-(void) dealloc;

-(void)encodeWithCoder: (NSCoder*) coder;

-(void) buildArticleList;
-(NSArray*) feedList;
-(NSArray*) articleList;

-(void)removeFeed: (RSSFeed*) feed;
-(void)addFeedWithURL: (NSURL*) url;
-(void)addFeedsWithURLs: (NSArray*) urls;
-(void)addFeed: (RSSFeed*) feed;
-(void)addFeeds: (NSArray*) feeds;

-(BOOL) articleListDirty;
-(void) setArticleListDirty: (BOOL) isDirty;

@end


FeedList* getFeedList();


#endif // _FEEDLIST_H_


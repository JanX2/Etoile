/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#import "RSSFeed.h"

/*
 * The RSSArticleCreationListener is a object which collects things
 * to put into a new article and puts the articles together.
 * It does what otherwise every individual RSS-style parser had to do
 * for itself.
 */
@interface RSSArticleComposer : NSObject
{
  //RSSFeed* currentFeed;
  id delegate;
  
  NSString* headline;
  NSString* url;
  NSString* summary;
  NSString* content;
  NSDate* date;
  
  NSMutableArray* links;
  
  //NSMutableArray* currentArticleList;
}

// Initializers & Deallocation
//-(id) initWithFeed: (RSSFeed*) aFeed;
-(id) init;
-(void) dealloc;

// delegate accessors
-(void) setDelegate: (id)aDelegate;
-(id) delegate;

// Basic control
-(void) nextArticle;
-(void) startArticle;
-(void) commitArticle;
-(void) finished;

//-(void) setFeed: (RSSFeed*) aFeed;

// Collecting of article content
-(void) setHeadline: (NSString*) aHeadline;
-(void) addLinkWithURL: (NSString*) anURL;
-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation;
-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation
	       andType: (NSString*) aType;
-(void) setContent: (NSString*) aContent;
-(void) setSummary: (NSString*) aSummary;
-(void) setDate: (NSDate*) aDate;


@end


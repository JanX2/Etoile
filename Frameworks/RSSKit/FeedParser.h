/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation, in version 2.1
 *  of the License
 * 
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "DOMParser.h"
#import "RSSArticleCreationListener.h"

@interface FeedParser : RSSArticleComposer
{
}

// instantiation

+(id) parser;
+(id) parserWithDelegate: (id)aDelegate;
-(id) init;

// parsing

-(void) parseWithRootNode: (XMLNode*) root;




// helper methods

-(NSString*) stringFromHTMLAtNode: (XMLNode*) root;

/**
 * Gets called when a feed title has been found in the feed.
 */
-(void) foundFeedName: (NSString*) feedName;

@end

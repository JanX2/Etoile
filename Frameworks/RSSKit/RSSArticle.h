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


#import <objc/objc.h>
#import <Foundation/Foundation.h>

@class RSSArticle;

#import "RSSFeed.h"

/**
 * An object of this class represents an article in an RSS Feed.
 */
@interface RSSArticle : NSObject <NSCoding>
{
@private
  NSString*  headline;
  NSString*  url;
  NSString*  description;
  NSDate*    date;
  
  /// Links and multimedia content
  NSMutableArray* links;
  
  RSSFeed*   feed;
}

/**
 * Standard initializer. You shouldn't use this. Better use
 * initWithHeadline:url:description:date:
 *
 * @see initWithHeadline:url:description:date:
 */
-init;

/**
 * Designated initializer for the RSSArticle class.
 *
 * Don't create RSSArticle objects yourself. Create a RSSFeed
 * object and let it fetch the articles for you!
 *
 * @param myHeadline A NSString containing the headline of the article.
 * @param myUrl A NSString containing the URL of the
 *              full version of the article.
 * @param myDescription An excerpt of the article text or the full text.
 * @param myDate The date as NSDate object on which this article was posted.
 * @see RSSFeed
 */
-initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     date: (NSDate*)   myDate;

/**
 * Old designated initializer for the RSSArticle class.
 * Only here for compatibility reasons. This method is likely
 * to be dropped in future versions.
 * @deprecated
 *
 * @param myHeadline A NSString containing the headline of the article.
 * @param myUrl A NSString containing the URL of the
 *              full version of the article.
 * @param myDescription An excerpt of the article text or the full text.
 * @param myTime The date (in seconds since 1970) on which this
 *               article was posted.
 */
-initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     time: (unsigned int) myTime;


-(void) dealloc;


// NSCoding methods

/// Deserializes a RSSArticle object from a NSCoder
-(id)initWithCoder: (NSCoder*)coder;

/// Serializes a RSSArticle object to a NSCoder
-(void)encodeWithCoder: (NSCoder*)coder;

// end of NSCoding methods

/// @return The headline of the article
-(NSString*)headline;

/// @return Te URL of the full version of the article (as NSString*)
-(NSString*)url;

/// @return The full text, an excerpt or a summary from the article
-(NSString*)description;

/**
 * Adds a new link to this article.
 * This is a NSURL object, which usually has
 * the "type" property set to an NSString which
 * represents the resource's MIME type. You may
 * also specify the "rel" property, which should
 * be one of "enclosure", "related", "alternate",
 * "via".
 */
-(void)addLink:(NSURL*) anURL;

/**
 * Replaces the list of links with a new one.
 * See the documentation for addLink: for details.
 * Hint: The parameter may also be nil.
 */
-(void)setLinks:(NSMutableArray*) someLinks;

/** 
 * Returns an NSArray containing NSURL objects or nil,
 * if there are none. The contained NSURL objects often
 * have the "type" and "rel" properties set. See the
 * documentation for addLink: for details.
 *
 * @return The links of the article.
 */
-(NSArray*) links;

/**
 * Returns the date of the publication of the article.
 * If the source feed of this article didn't contain information
 * about this date, the fetching date is usually returned.
 *
 * @return The date of the publication of the article
 */
-(NSDate*) date;

-(void)feed:(RSSFeed*)aFeed;

/**
 * Returns the source feed of this article.
 *
 * @warning It's not guaranteed that this object actually exists.
 *          Be aware of segmentation faults!
 *
 * If you want to make sure the object exists, you have to follow
 * these rules:
 *
 * <ul>
 *  <li>Don't retain any article!</li>
 *  <li>Don't call the (undocumented) <code>feed:</code> (Colon!) method.</li>
 * </ul>
 * 
 * @return The source feed of this article
 */
-(RSSFeed*)feed;


// Equality and hash codes
- (unsigned) hash;
- (BOOL) isEqual: (id)anObject;

@end

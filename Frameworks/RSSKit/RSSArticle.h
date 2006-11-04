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


#import <objc/objc.h>
#import <Foundation/Foundation.h>

@class RSSArticle;

#import "RSSFeed.h"


/**
 * Classes implementing this protocol can be used as RSSArticles.
 */
@protocol RSSArticle <NSObject>
/// @return The headline of the article
-(NSString*)headline;

/// @return The URL of the full version of the article (as NSString*)
-(NSString*)url;

/// @return The full text, an excerpt or a summary from the article
-(NSString*)content;

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

/**
 * Returns the Enclosure object of this article as URL.
 * If there is no enclosure object, nil is returned.
 * 
 * @return the URL of this article's enclosure object
 */
-(NSURL*)enclosure;

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
 *  <li>Don't call the (undocumented) <code>setFeed:</code> (Colon!) method.</li>
 * </ul>
 * 
 * @return The source feed of this article
 */
-(RSSFeed*)feed;

@end

/**
 * Instances conforming to this protocol can be modified. Applications
 * usually don't want to modify articles, as they are already created by the
 * feeds, so handing around articles as id<RSSArticle> is a good way to ensure
 * nobody (without malicious intentions) is going to change them.
 */
@protocol RSSMutableArticle <RSSArticle>

/**
 * Adds a new link to this article.
 * This is a RSSLink object, which usually has
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
-(void)setLinks: (NSArray*) someLinks;

/**
 * Only internally used to set the feed for the receiver. (Non-retained!)
 */
-(void)setFeed:(RSSFeed*)aFeed;

@end



/**
 * An object of this class represents an article in an RSS Feed.
 */
@interface RSSArticle : NSObject <NSCoding,RSSMutableArticle>
{
@private
  NSString*  headline;
  NSString*  url;
  NSString*  description;
  NSDate*    date;
  NSURL*     enclosure;
  
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


// NSCoding methods for serialization
-(id)initWithCoder: (NSCoder*)coder;
-(void)encodeWithCoder: (NSCoder*)coder;

// Accessor methods (conformance to RSSArticle protocol)
-(NSString*)headline;
-(NSString*)url;
-(NSString*)content;
-(NSString*)description;
-(NSArray*) links;
-(NSDate*) date;
-(NSURL*)enclosure;

// Mutability methods (conformance to RSSMutableArticle protocol)
-(void)addLink:(NSURL*) anURL;
-(void)setLinks: (NSArray*) someLinks;
-(void)setFeed:(RSSFeed*)aFeed;

// Equality and hash codes
- (unsigned) hash;
- (BOOL) isEqual: (id)anObject;

@end

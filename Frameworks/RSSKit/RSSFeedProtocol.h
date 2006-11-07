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

#import <Foundation/Foundation.h>


// --- Notifications ---

/** 
 * When feed finishes parsing, it posts this notification
 * with itself as object and nil for userInfo.
 **/
extern NSString *const RSSFeedFetchedNotification;
/**
 * When feed fetching in background failed or feed fails to process data,
 * it posts this notification
 * with itself as object.
 * userInfo: @"Reason" for a string of failed reason. It could be nil.
 **/
extern NSString *const RSSFeedFetchFailedNotification;

/**
 * When a feed is about to fetch, it first posts this notification
 * with itself as object and nil as userInfo.
 */
extern NSString *const RSSFeedWillFetchNotification;

// ---------------------

// There's also a RSSArticle protocol, but we don't need to know details,
// as we're only passing references around in the RSSFeed protocol.
@protocol RSSArticle;

/**
 * The errors that can occur when fetching a feed.
 */
enum RSSFeedError
  {
    RSSFeedErrorNoError = 0,         ///< No error occured
    RSSFeedErrorNoFetcherError,      ///< @deprecated
    RSSFeedErrorMalformedURL,        ///< Malformed URL
    RSSFeedErrorDomainNotKnown,      ///< Domain not known
    RSSFeedErrorServerNotReachable,  ///< Server not reachable
    RSSFeedErrorDocumentNotPresent,  ///< Document not present on server
    RSSFeedErrorMalformedRSS         ///< Malformed RSS / Parsing error
  };


/**
 * The RSS feed protocol defines the way users are supposed to talk to
 * a feed.
 */
@protocol RSSFeed
/**
 * @return an enumerator for the articles in this feed
 */
- (NSEnumerator*) articleEnumerator;

/**
 * Returns YES if and only if this feed is currently being fetched.
 */
- (BOOL)isFetching;

/**
 * @return The name of the feed
 */
- (NSString*) feedName;

/**
 * @return the URL where the feed can be downloaded from (as NSURL object)
 * @see NSURL
 */
- (NSURL*) feedURL;

/**
 * Fetches the feed from the web.
 *
 * @return An error number (of type enum RSSFeedError)
 * @see NSURL
 * @see RSSFeedError
 */
- (enum RSSFeedError) fetch;

/**
 * Fetches the feed from the web. Feed fetching is done
 * in the background. When the feed is fetched, the feed
 * will post a RSSFeedFetchedNotification.
 *
 * @see RSSFeedFetchedNotification
 **/
- (void) fetchInBackground;

/**
 * Returns the last fetching error.
 */
- (enum RSSFeedError) lastError;

/**
 * Returns a NSDictionary object that is property-list compatible and
 * contains all information required to rebuild this article object.
 */
- (NSDictionary*) plistDictionary;
@end

@protocol RSSMutableFeed <RSSFeed>
/**
 * Deletes an article from the feed.
 *
 * @param article The article to delete.
 */
- (void) removeArticle: (id<RSSArticle>) article;


/**
 * Sets the feed name
 */
- (void) setFeedName: (NSString*) aFeedName;

@end


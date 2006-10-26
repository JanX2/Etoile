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

@class RSSFeed;


#import "RSSArticle.h"

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
 * The states that the RSS feed can have.
 */
enum RSSFeedStatus
  {
    RSSFeedIsFetching,
    RSSFeedIsIdle
  };

/**
 * The protocol for RSSFeed delegate objects.
 */
@protocol RSSFeedDelegate;

/**
 * Objects of this class represent a RSS/ATOM feed, which is basically
 * just a source for new articles. When creating a RSSFeed object, you'll
 * just have to provide it with the URL, where the feed can be downloaded
 * from.
 * 
 * This is the generic way to read feeds:
 *
 * <ul>
 *  <li>Create a URL object with the location of the feed.<br>
 *    <code>
 *      NSURL*   url =
 *         [NSURL URLWithString:@"http://www.example.com/feed.xml"];
 *    </code>
 *  </li>
 *  <li>Create a RSSFeed object with the URL:<br>
 *    <code>
 *      RSSFeed* feed = [RSSFeed initWithURL: url];
 *    </code>
 *  </li>
 *  <li>Fetch the contents of the feed:<br>
 *    <code>
 *      enum RSSFeedError err = [feed fetch];
 *    </code>
 *  </li>
 *  <li>Optionally tell the RSSFeed to keep old articles.<br>
 *    <code>
 *      [feed setAutoClear: NO];
 *    </code>
 *  </li>
 *  <li>Iterate over the articles contained in the feed.
 *      This is analogous to the iteration over a NSArray.
 *    <pre>
 *      int i;
 *      for (i=0; i<[feed count]; i++)
 *        {
 *          RSSArticle* myArticle = [feed articleAtIndex: i];
 *          // [...] more code here
 *        }
 *    </pre>
 *  </li>
 * </ul>
 *
 *
 * @see initWithURL:
 * @see fetch
 * @see setAutoClear:
 *
 * @see RSSArticle
 * @see NSURL
 */
@interface RSSFeed : NSObject <NSCoding>
{
@protected
  NSDate*           lastRetrieval;
  BOOL              clearFeedBeforeFetching;
  NSArray*          articles;
  enum RSSFeedError lastError;
  NSString*         feedName;
  NSURL*            feedURL;
  Class             articleClass;
  
  enum RSSFeedStatus status;
  NSRecursiveLock*  lock;

  NSMutableData *cacheData; // Used only when load in background.
  
  id<RSSFeedDelegate> _delegate;
}


+feed;
+feedWithURL: (NSURL*) aURL;

-init;

/**
 * Designated initializer.
 * 
 * @param aURL The URL where the feed can be downloaded from.
 */
-initWithURL: (NSURL*) aURL;


/**
 * @return Description of the Feed (the feed name)
 */
-(NSString*) description;

// ----------------------------------------------------------------------
// The RSSFeed's delegate
// ----------------------------------------------------------------------

-(void)setDelegate: (id<RSSFeedDelegate>)aDelegate;
-(id<RSSFeedDelegate>)delegate;

// ----------------------------------------------------------------------
// NSCoding methods
// ----------------------------------------------------------------------

-(id)initWithCoder: (NSCoder*)coder;
-(void)encodeWithCoder: (NSCoder*)coder;


// ----------------------------------------------------------------------
// Status access
// ----------------------------------------------------------------------

/**
 * Accessor for the status of the feed.
 * This can be used by a multithreaded GUI to indicate if a feed
 * is currently fetching...
 *
 * @return either RSSFeedIsFetching or RSSFeedIsIdle
 */
- (enum RSSFeedStatus) status;


// ----------------------------------------------------------------------
// Access to the articles
// ----------------------------------------------------------------------

/**
 * Lets you access the individual articles in the feed.
 * Often used in conjunction with the count method. Also
 * take a look at the example in the description of this
 * class. (RSSFeed)
 * 
 * @param index of the article to get
 * @return Article number index
 * @see RSSArticle
 * @see count
 * @see RSSFeed
 */
- (RSSArticle*) articleAtIndex: (int) index;

/**
 * @return the number of articles in this feed.
 */
- (unsigned int) count;

/**
 * @return an enumerator for the articles in this feed
 */
- (NSEnumerator*) articleEnumerator;

/**
 * Deletes an article from the feed.
 *
 * @param article The index of the article to delete.
 */
- (void) removeArticle: (RSSArticle*) article;



// ----------------------------------------------------------------------
// Access to the preferences
// ----------------------------------------------------------------------

/**
 * Sets the feed name
 */
- (void) setFeedName: (NSString*) aFeedName;

/**
 * @return The name of the feed
 */
- (NSString*) feedName;

/**
 * @return the URL where the feed can be downloaded from (as NSURL object)
 * @see NSURL
 */
- (NSURL*) feedURL;



// --------------------------------------------------------------------
// Equality and hash codes
// --------------------------------------------------------------------
- (unsigned) hash;
- (BOOL) isEqual: (id)anObject;


// --------------------------------------------------------------------
// Accessor and Mutator for the automatic clearing
// --------------------------------------------------------------------

/**
 * Lets you decide if the feed should be cleared before new
 * articles are downloaded.
 *
 * @param autoClear YES, if the feed should clear its article list
 *                  before fetching new articles. NO otherwise
 */
- (void) setAutoClear: (BOOL) autoClear;


/**
 * @return YES, if the automatic clearing of the article list is
 *         enabled for this feed. NO otherwise.
 */
- (BOOL) autoClear;


/**
 * Clears the list of articles.
 */
- (void) clearArticles;



// ------------------------------------------------------------------
// Extensions that make subclassing RSSFeed and RSSArticle easier.
// ------------------------------------------------------------------

/**
 * Sets the class of the article objects. This needs to be a subtype
 * of RSSArticle.
 *
 * @param aClass The class newly created article objects should have.
 */
-(void) setArticleClass:(Class)aClass;

/**
 * Returns the class of the article objects. This will be a subtype
 * of RSSArticle.
 *
 * @return the article class
 */
-(Class) articleClass;


// ------------------------------------------------------------------
// Dirtyness, now implemented via the date of last retrieval
// ------------------------------------------------------------------

/**
 * Returns the date of last retrieval of this feed.
 * If the feed hasn't been retrieved yet, this method returns nil.
 *
 * @return The date of last retrieval as a NSDate pointer.
 */
-(NSDate*) lastRetrieval;


/**
 * RSSFeed also implements the NewRSSArticleListener informal protocol.
 */
-(void) newArticleFound: (RSSArticle*) anArticle;

@end



/*
 * FIXME: Hide this interface in some other header file
 * so that programmers don't get confused.
 */

@interface RSSFeed (Private)

/**
 * Submits multiple articles to a feed. Is
 * used by the article creator class.
 *
 * @return YES on success, NO on failure.
 */
-(BOOL) _submitArticles: (NSArray*) newArticles;

@end


/**
 * The protocol for RSSFeed delegates.
 * TODO: Maybe an informal protocol could be more appropriate here if
 *       this protocol is about to grow.
 */
@protocol RSSFeedDelegate <NSObject>

/**
 * Inidcates that a new article has just been added to this feed.
 */
- (void) feed: (RSSFeed*) aFeed
 addedArticle: (RSSArticle*) anArticle;

@end

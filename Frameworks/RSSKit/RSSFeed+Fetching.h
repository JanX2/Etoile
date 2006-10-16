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


#import "RSSFeed.h"

/**
 * The ,,Fetching'' category of RSSFeed contains methods
 * for the RSSFeed class, which are responsible for fetching
 * and parsing feeds.
 */
@interface RSSFeed (Fetching)

/**
 * Returns the last error.
 * Guaranteed to return the last fetching result.
 */
-(enum RSSFeedError) lastError;

// get the document from the http server
-(enum RSSFeedError) setError: (enum RSSFeedError) err;

/**
 * Fetches the feed from the web (using NSURL).
 *
 * @return An error number (of type enum RSSFeedError)
 * @see NSURL
 * @see RSSFeedError
 */
-(enum RSSFeedError) fetch;

@end

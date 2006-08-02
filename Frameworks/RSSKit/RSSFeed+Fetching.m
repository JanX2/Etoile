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


#import "RSSFeed+Fetching.h"
#import "DublinCore.h"
#import "GNUstep.h"

// #define DEBUG 1


#import "DOMParser.h"

#import "FeedParser.h"
#import "Atom03Parser.h"
#import "Atom10Parser.h"
#import "RSS10Parser.h"
#import "RSS20Parser.h"


#define URI_ATOM10              @"http://www.w3.org/2005/Atom"
#define URI_PURL_CONTENT        @"http://purl.org/rss/1.0/modules/content/"
#define URI_PODCAST             @"http://www.itunes.com/dtds/podcast-1.0.dtd"
#define URI_PURL_CONTENT        @"http://purl.org/rss/1.0/modules/content/"
#define URI_PODCAST             @"http://www.itunes.com/dtds/podcast-1.0.dtd"
#define URI_PURL_DUBLINCORE     @"http://purl.org/dc/elements/1.1/"



@interface RSSFeed (PrivateFetching)
-(NSData*) fetchDataFromURL: (NSURL*) myURL;
-(enum RSSFeedError) fetchWithData: (NSData*)data;

-(enum RSSFeedError) parseATOM03WithRootNode: (XMLNode*) root;
-(enum RSSFeedError) parseATOM10WithRootNode: (XMLNode*) root;
-(enum RSSFeedError) parseRSS10WithRootNode: (XMLNode*) root;
-(enum RSSFeedError) parseRSS20WithRootNode: (XMLNode*) root;
@end




@implementation RSSFeed (PrivateFetching)
/**
 * Fetches the feed from the URL which is stored in the myURL
 * argument
 */
-(NSData*) fetchDataFromURL: (NSURL*) myURL
{
   NSData* data;
   
   if (myURL == nil) {
       [self setError: RSSFeedErrorMalformedURL];
   }
   
   data = [myURL resourceDataUsingCache: NO];
   
   if (data == nil) {
       [self setError: RSSFeedErrorServerNotReachable];
   }
   
   return [[data retain] autorelease];
}




// parse ATOM 1.0
-(enum RSSFeedError) parseATOM10WithRootNode: (XMLNode*) root
{
  FeedParser* parser = [Atom10Parser parserWithDelegate: self];
  [parser parseWithRootNode: root];
  return RSSFeedErrorNoError;
}

// parse ATOM 0.3
-(enum RSSFeedError) parseATOM03WithRootNode: (XMLNode*) root
{
  FeedParser* parser = [Atom03Parser parserWithDelegate: self];
  [parser parseWithRootNode: root];
  return RSSFeedErrorNoError;
}

// parse RSS 2.0
-(enum RSSFeedError) parseRSS20WithRootNode: (XMLNode*) root
{
  FeedParser* parser = [RSS20Parser parserWithDelegate: self];
  [parser parseWithRootNode: root];
  return RSSFeedErrorNoError;
}

// parse RSS 1.0
-(enum RSSFeedError) parseRSS10WithRootNode: (XMLNode*) root
{
  FeedParser* parser = [RSS10Parser parserWithDelegate: self];
  [parser parseWithRootNode: root];
  return RSSFeedErrorNoError;
}



/**
 * @private
 * Uses the feed contained in data instead of the URL.
 */
-(enum RSSFeedError) fetchWithData: (NSData*)data
{ 
  NSString* rssVersion;
  
  NSXMLParser* parser;
  XMLNode* root;
  XMLNode* document;
  
  parser = AUTORELEASE([[NSXMLParser alloc] initWithData: data]);
  
  document = AUTORELEASE([[XMLNode alloc]
			   initWithName: nil
			   namespace: nil
			   attributes: nil
			   parent: nil]);
  
  [parser setDelegate: document];
  
  
  if ([parser parse] == NO)
    {
      return [self setError: RSSFeedErrorMalformedRSS];
    }
  
#ifdef DEBUG
  NSLog(@"document was:\n%@", [document content]);
#endif // DEBUG
  
  root = [document firstChildElement]; // finds the root node
  
  if (clearFeedBeforeFetching == YES)
    {
      status = RSSFeedIsIdle;
      [self clearArticles];
    }
  
  
  // FIXME: Catch errors here which are returned from parsing methods!
  if ([[root name] isEqualToString: @"RDF"]) // RSS 1.0 detected
    {
      rssVersion = @"RSS 1.0";
      [self parseRSS10WithRootNode: root];
    }
  else if ([[root name] isEqualToString: @"rss"] &&
	   [[[root attributes] objectForKey: @"version"]
	     isEqualToString: @"2.0"]) // RSS 2.0 detected
    {
      rssVersion = @"RSS 2.0";
      [self parseRSS20WithRootNode: root];
    }
  else if ([[root name] isEqualToString: @"rss"] &&
	   [[[root attributes] objectForKey: @"version"]
	     isEqualToString: @"0.91"]) // RSS 0.91 detected
    {
      rssVersion = @"RSS 0.91";
      NSLog(@"WARNING: RSS 0.91 support is a *hack* at the moment");
      [self parseRSS20WithRootNode: root];
    }
  else if ([[root name] isEqualToString: @"feed"] &&
	   [[root namespace] isEqualToString: URI_ATOM10]) // ATOM 1.0
    {
      rssVersion = @"ATOM 1.0";
      [self parseATOM10WithRootNode: root];
    }
  else if ([[root name] isEqualToString: @"feed"] &&
	   [[[root attributes] objectForKey: @"version"]
	     isEqualToString: @"0.3"])   // ATOM 0.3 detected
    {
      rssVersion = @"ATOM 0.3";
      [self parseATOM03WithRootNode: root];      
    }
  else
    {
      rssVersion = @"Malformed RSS?";
      status = RSSFeedIsIdle;
      return [self setError: RSSFeedErrorMalformedRSS];
    }
  
  [[NSNotificationCenter defaultCenter]
          postNotificationName: @"FeedFetchedNotification"
                        object: self];
  
  status = RSSFeedIsIdle;
  return [self setError: RSSFeedErrorNoError];
}


@end




@implementation RSSFeed (Fetching)



/**
 * Returns the last error.
 * Guaranteed to return the last fetching result.
 */
-(enum RSSFeedError) lastError
{
  return lastError;
}

// sets the error for the feed (see RSSFeed.h)
-(enum RSSFeedError) setError: (enum RSSFeedError) err
{
  lastError = err;
  return err;
}

/**
 * Fetches the feed from its feed URL, parses it and adds the found
 * articles to the list of articles contained in this feed (if they
 * are new).
 */
-(enum RSSFeedError) fetch
{
   NSData* data;
   
   status = RSSFeedIsFetching;
   
   // no errors at first :-)
   [self setError: RSSFeedErrorNoError];
   
   data = [self fetchDataFromURL: feedURL];
   
   status = RSSFeedIsIdle;
   
   return [self fetchWithData: data];
}

@end



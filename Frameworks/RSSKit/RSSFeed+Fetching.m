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

// fetches the feed
-(enum RSSFeedError) fetch
{ 
  NSString* rssVersion;
  
  NSXMLParser* parser;
  XMLNode* root;
  XMLNode* document;
  NSData* data;
  
  // mark as fetching
  status = RSSFeedIsFetching;
  
  if (feedURL == nil)
    {
      status = RSSFeedIsIdle;
      return [self setError: RSSFeedErrorMalformedURL];
    }
  
  data = [feedURL resourceDataUsingCache: NO];
  
  if (data == nil)
    {
      status = RSSFeedIsIdle;
      return [self setError: RSSFeedErrorServerNotReachable];
    }
  
  parser = AUTORELEASE([[NSXMLParser alloc] initWithData: data]);
  
  document = AUTORELEASE([[XMLNode alloc]
			   initWithName: nil
			   namespace: nil
			   attributes: nil
			   parent: nil]);
  
  [parser setDelegate: document];
  
  
  if ([parser parse] == NO)
    {
      status = RSSFeedIsIdle;
      return [self setError: RSSFeedErrorMalformedRSS];
    }
  
#ifdef DEBUG
  NSLog(@"document was:\n%@", [document content]);
#endif // DEBUG
  
  root = [document firstChildElement]; // finds the root node
  
  if (clearFeedBeforeFetching == YES)
    {
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
  
  status = RSSFeedIsIdle;
  return [self setError: RSSFeedErrorNoError];
}

@end

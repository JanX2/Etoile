// -*-objc-*-


#import "RSSFeed+Fetching.h"
#import "DublinCore.h"
#import "GNUstep.h"

// #define DEBUG 1


#import "DOMParser.h"


#define URI_ATOM10              @"http://www.w3.org/2005/Atom"
#define URI_PURL_CONTENT        @"http://purl.org/rss/1.0/modules/content/"
#define URI_PURL_DUBLINCORE     @"http://purl.org/dc/elements/1.1/"

#define REL_KEY @"rel"
#define TYPE_KEY @"type"

/*
 * The RSSArticleCreationListener is a object which collects things
 * to put into a new article and puts the articles together.
 * It does what otherwise every individual RSS-style parser had to do
 * for itself.
 */

@interface RSSArticleCreationListener : NSObject
{
  RSSFeed* currentFeed;
  
  NSString* headline;
  NSString* url;
  NSString* summary;
  NSString* content;
  NSDate* date;
  
  NSMutableArray* links;
  
  NSMutableArray* currentArticleList;
}

// Initializers & Deallocation
-(id) initWithFeed: (RSSFeed*) aFeed;
-(id) init;
-(void) dealloc;

// Basic control
-(void) nextArticle;
-(void) startArticle;
-(void) commitArticle;
-(void) finished;
-(void) setFeed: (RSSFeed*) aFeed;

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

@implementation RSSArticleCreationListener

-(id) initWithFeed: (RSSFeed*) aFeed
{
  self = [super init];
  if (self != nil)
    {
      [self setFeed: aFeed];
    }
  
  currentArticleList = [[NSMutableArray alloc] initWithCapacity: 10];
  
  return self;
}

-(id) init
{
  return [self initWithFeed: nil];
}

-(void) dealloc
{
  DESTROY(currentFeed);
  DESTROY(headline);
  DESTROY(url);
  DESTROY(summary);
  DESTROY(content);
  DESTROY(date);
  
  DESTROY(links);
  DESTROY(currentArticleList);
  
  [super dealloc];
}

/**
 * Adds the article to the feed
 */
-(void) commitArticle
{
  RSSArticle* article;
  NSDate* articleDate;
  NSString* desc;
  
  // date
  if( date == nil )
    {
      articleDate = [[NSDate alloc] init];
    }
  else
    {
      articleDate = RETAIN(date);
    }
  
  // description
  if (content != nil)
    {
      desc = content;
    }
  else if (summary != nil)
    {
      desc = summary;
    }
  else
    {
      desc = @"No content.";
    }
  
  // create
  article = [[[currentFeed articleClass] alloc]
	      initWithHeadline: headline
	      url: url
	      description: desc
	      date: articleDate];
  
  // add information to which feed it belongs
  [article feed: currentFeed];
  
  // add links
  if ([links count] > 0)
    {
      [article setLinks: links];
    }
  
  // submit article
  NSLog(@"Commit, links is %@", links);
  [currentArticleList addObject: article];
  
  RELEASE(date);
  
  // desc needs NOT to be released or retained (only tmp ptr!)
}


/**
 * Gets called whenever a feed has been parsed completely.
 * Finally submits all fetched articles to the feed.
 */
-(void) finished
{
  NSLog(@"%@ finished, rc=%d", self, [self retainCount]);
  [currentFeed _submitArticles: currentArticleList];
}


/**
 * Starts a new article
 */
-(void) startArticle
{
  NSLog(@"start article");
  
  NSLog(@"retain counts in start article: %d %d %d",
	[headline retainCount],
	[links retainCount],
	[date retainCount]);
  // Free all old stuff
  RELEASE(headline);
  RELEASE(url);
  RELEASE(summary);
  RELEASE(content);
  RELEASE(date);
  
  RELEASE(links);
  
  // Set default values
  headline = @"No headline";
  url = nil;
  summary = nil;
  content = nil;
  date = nil;
  
  links = [[NSMutableArray alloc] initWithCapacity: 1];
}

// don't use this, use commitArticle
// and startArticle directly instead!
-(void) nextArticle
{
  NSLog(@"Warning: nextArticle should not be called.");
  [self commitArticle];
  [self startArticle];
}

-(void) setFeed: (RSSFeed*) aFeed
{
  RELEASE(currentFeed);
  currentFeed = RETAIN(aFeed);
}


-(void)setHeadline: (NSString*) aHeadline
{
  RELEASE(headline);
  headline = RETAIN(aHeadline);
}

-(void) addLinkWithURL: (NSString*) anURL
{
  // default is 'alternate', see ATOM specification!
  [self addLinkWithURL: anURL
	andRel: @"alternate"];
}

-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation
{
  [self addLinkWithURL: anURL
	andRel: aRelation
	andType: nil];
}

-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation
	       andType: (NSString*) aType
{
  NSURL* actualURL;
  
  NSLog(@"addLinkWithURL: %@ andRel: %@ andType: %@",
	anURL, aRelation, aType);
  
  actualURL = [[NSURL alloc] initWithString: anURL];
  
  if (aType != nil)
    {
      [actualURL setProperty: aType
		 forKey: TYPE_KEY];
    }
  
  if (aRelation != nil)
    {
      [actualURL setProperty: aRelation
		 forKey: REL_KEY];
      
      if ([aRelation isEqualToString: @"alternate"])
	{
	  RELEASE(url);
	  url = RETAIN(anURL); // anURL, the String version!
	}
    }
  
  [links addObject: actualURL];
  RELEASE(actualURL);
  
  NSLog(@"links is now %@", links);
}

-(void) setContent: (NSString*) aContent
{
  RELEASE(content);
  content = RETAIN(aContent);
}

-(void) setSummary: (NSString*) aSummary
{
  RELEASE(summary);
  summary = RETAIN(aSummary);
}

-(void) setDate: (NSDate*) aDate
{
  RELEASE(date);
  date = RETAIN(aDate);
}
@end


@implementation RSSFeed (Fetching)


// FIXME: Do some HTML parsing here...
// Just a stub...
-(NSString*) stringFromHTMLAtNode: (XMLNode*) root
{
  return AUTORELEASE(RETAIN([root content]));
}

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
  RSSArticleCreationListener* creator;
  XMLNode* toplevelnode;
  XMLNode* secondlevelnode;
  
  creator = AUTORELEASE([[RSSArticleCreationListener alloc]
			  initWithFeed: self]);
  
  for ( toplevelnode = [root firstChildElement];
	toplevelnode != nil;
	toplevelnode = [toplevelnode nextElement] )
    {
      if ([[toplevelnode name]
	    isEqualToString: @"title"])
	{
	  RELEASE(feedName);
	  feedName = RETAIN([toplevelnode content]);
	}
      else if ([[toplevelnode name]
		 isEqualToString: @"entry"])
	{
	  [creator startArticle];
	  
	  for (secondlevelnode = [toplevelnode firstChildElement];
	       secondlevelnode != nil;
	       secondlevelnode = [secondlevelnode nextElement] )
	    {
	      if ([[secondlevelnode name]
		    isEqualToString: @"title"])
		{
		  [creator setHeadline: [secondlevelnode content]];
		}
	      // FIXME: ATOM 0.3 specifies different storage
	      // modes like Base64, plain ASCII etc. Implement these!
	      // 1.0, too?
	      else if ([[secondlevelnode name]
			 isEqualToString: @"summary"])
		{
		  [creator setSummary: [secondlevelnode content]];
		}
	      else if ([[secondlevelnode name]
			 isEqualToString: @"content"])
		{
		  register NSString* tmp =
		    (NSString*)
		    [[secondlevelnode attributes]
		      objectForKey: @"type"];
		  
		  if (tmp == nil)
		    [creator setContent: [secondlevelnode content]];
		  else
		    {
		      if ([tmp isEqualToString: @"application/xhtml+xml"] ||
			  [tmp isEqualToString: @"xhtml"])
			{
			  [creator setContent: [self stringFromHTMLAtNode: secondlevelnode]];
			}
		    }
		}
	      else if ([[secondlevelnode name]
			 isEqualToString: @"issued"] ||
		       [[secondlevelnode name]
			 isEqualToString: @"updated"])
		{
		  [creator setDate: parseDublinCoreDate( [secondlevelnode content]) ];
		}
	      else if ([[secondlevelnode name]
			 isEqualToString: @"link"])
		{
		  [creator
		    addLinkWithURL: [[secondlevelnode attributes]
				      objectForKey: @"href"]
		    andRel: [[secondlevelnode attributes]
				  objectForKey: @"rel"]
		    andType: [[secondlevelnode attributes]
				  objectForKey: @"type"]
		   ];
		}
	    }
	  [creator commitArticle];
	}
    }
  
  [creator finished];
  return RSSFeedErrorNoError;
}



// parse ATOM 0.3
-(enum RSSFeedError) parseATOM03WithRootNode: (XMLNode*) root
{
  RSSArticleCreationListener* creator;
  XMLNode* toplevelnode;
  XMLNode* secondlevelnode;
  
  creator = AUTORELEASE([[RSSArticleCreationListener alloc]
			  initWithFeed: self]);
  
  for ( toplevelnode = [root firstChildElement];
	toplevelnode != nil;
	toplevelnode = [toplevelnode nextElement] )
    {
      if ([[toplevelnode name]
	    isEqualToString: @"title"])
	{
	  RELEASE(feedName);
	  feedName = RETAIN([toplevelnode content]);
	}
      else if ([[toplevelnode name]
		 isEqualToString: @"entry"])
	{
	  [creator startArticle];
	  
	  for (secondlevelnode = [toplevelnode firstChildElement];
	       secondlevelnode != nil;
	       secondlevelnode = [secondlevelnode nextElement] )
	    {
	      if ([[secondlevelnode name]
		    isEqualToString: @"title"])
		{
		  [creator setHeadline: [secondlevelnode content]];
		}
	      // FIXME: ATOM 0.3 specifies different storage
	      // modes like Base64, plain ASCII etc. Implement these!
	      else if ([[secondlevelnode name]
			 isEqualToString: @"summary"])
		{
		  [creator setSummary: [secondlevelnode content]];
		}
	      else if ([[secondlevelnode name]
			 isEqualToString: @"content"])
		{
		  register NSString* tmp =
		    (NSString*)
		    [[secondlevelnode attributes]
		      objectForKey: @"type"];
		  
		  if (tmp == nil)
		    [creator setContent: [secondlevelnode content]];
		  else
		    {
		      if ([tmp isEqualToString: @"application/xhtml+xml"] ||
			  [tmp isEqualToString: @"xhtml"])
			{
			  [creator setContent: [self stringFromHTMLAtNode: secondlevelnode]];
			}
		    }
		}
	      /*
	       * FIXME: is 'updated' instead of 'issued'
	       * also included in ATOM 0.3? (it is in 1.0)
	       */
	      else if ([[secondlevelnode name]
			 isEqualToString: @"issued"])
		{
		  [creator setDate: parseDublinCoreDate( [secondlevelnode content] )];
		}
	      else if ([[secondlevelnode name]
			 isEqualToString: @"link"])
		{
		  [creator
		    addLinkWithURL: [[secondlevelnode attributes]
				      objectForKey: @"href"]
		    andRel: [[secondlevelnode attributes]
				  objectForKey: @"rel"]
		    andType: [[secondlevelnode attributes]
				  objectForKey: @"type"]
		   ];
		}
	    }
	  [creator commitArticle];
	}
    }
  [creator finished];
  return RSSFeedErrorNoError;
}

// parse RSS 2.0
-(enum RSSFeedError) parseRSS20WithRootNode: (XMLNode*) root
{
  RSSArticleCreationListener* creator;
  XMLNode* toplevelnode;
  XMLNode* secondlevelnode;
  XMLNode* thirdlevelnode;
  
  creator = AUTORELEASE([[RSSArticleCreationListener alloc]
			  initWithFeed: self]);
  
  for ( toplevelnode = [root firstChildElement];
	toplevelnode != nil;
	toplevelnode = [toplevelnode nextElement] )
    {
      if ([[toplevelnode name]
	    isEqualToString: @"channel"])
	{
	  for (secondlevelnode = [toplevelnode firstChildElement];
	       secondlevelnode != nil;
	       secondlevelnode = [secondlevelnode nextElement] )
	    {
	      if ([[secondlevelnode name]
		    isEqualToString: @"title"])
		{
		  RELEASE(feedName);
		  feedName = RETAIN([secondlevelnode content]);
		}
	      // FIXME: Add support for tags: link,description,
	      // language,managingEditor,webMaster
	      else if ([[secondlevelnode name]
		    isEqualToString: @"item"])
		{
		  [creator startArticle];
		  
		  for (thirdlevelnode =[secondlevelnode firstChildElement];
		       thirdlevelnode != nil;
		       thirdlevelnode =[thirdlevelnode nextElement])
		    {
		      if ([[thirdlevelnode name]
			    isEqualToString: @"title"])
			{
			  [creator setHeadline: [thirdlevelnode content]];
			}
		      else if ([[thirdlevelnode name]
				 isEqualToString: @"link"])
			{
			  [creator addLinkWithURL: [thirdlevelnode content]];
			}
		      else if ([[thirdlevelnode name]
				 isEqualToString: @"description"])
			{
			  [creator setSummary: [thirdlevelnode content]];
			}
		      else if ([[thirdlevelnode name]
				 isEqualToString: @"encoded"])
			{
			  if ([[thirdlevelnode namespace]
				isEqualToString: URI_PURL_CONTENT])
			    {
			      [creator setContent: [thirdlevelnode content]];
			      //NSLog(@"Content:Encoded: %@", description);
			    }
			}
		      else if ([[thirdlevelnode name]
				 isEqualToString: @"date"] &&
			       [[thirdlevelnode namespace]
				 isEqualToString: URI_PURL_DUBLINCORE])
			{
			  [creator setDate: parseDublinCoreDate([thirdlevelnode content])];
			}
		    }
		  
		  [creator commitArticle];
		}
	    }
	}
    }
  [creator finished];
  return RSSFeedErrorNoError;
}

// parse RSS 1.0
-(enum RSSFeedError) parseRSS10WithRootNode: (XMLNode*) root
{
  RSSArticleCreationListener* creator;
  XMLNode* toplevelnode;
  XMLNode* secondlevelnode;
  
  creator = AUTORELEASE([[RSSArticleCreationListener alloc] initWithFeed: self]);
  
  for ( toplevelnode = [root firstChildElement];
	toplevelnode != nil;
	toplevelnode = [toplevelnode nextElement] )
    {
      if ([[toplevelnode name] isEqualToString: @"channel"])
	{
	  for (secondlevelnode = [toplevelnode firstChildElement];
	       secondlevelnode != nil;
	       secondlevelnode = [secondlevelnode nextElement] )
	    {
	      if ([[secondlevelnode name]
		    isEqualToString: @"title"])
		{
		  RELEASE(feedName);
		  feedName = RETAIN([secondlevelnode content]);
		}
	      /* you could add here: link, description, image,
	       * items, textinput
	       */
	    }
	}
      else
	if ([[toplevelnode name]
	      isEqualToString: @"item"])
	  {
	    [creator startArticle];
	    
	    for (secondlevelnode = [toplevelnode firstChildElement];
		 secondlevelnode != nil;
		 secondlevelnode = [secondlevelnode nextElement] )
	      {
		if ([[secondlevelnode name]
		      isEqualToString: @"title"])
		  {
		    [creator setHeadline: [secondlevelnode content]];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"description"])
		  {
		    [creator setSummary: [secondlevelnode content]];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"link"])
		  {
		    [creator addLinkWithURL: [secondlevelnode content]
			     andRel: @"alternate"];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"date"] &&
			 [[secondlevelnode namespace]
			   isEqualToString: URI_PURL_DUBLINCORE])
		  {
		    [creator setDate: parseDublinCoreDate( [secondlevelnode content] )];
		  }
	      }
	    [creator commitArticle];
	  }
    }
  
  [creator finished];
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
      rssVersion = @"ATOM 1.0 (draft)";
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


#import "RSS10Parser.h"

@implementation RSS10Parser

- (void) parseWithRootNode: (XMLNode*) root
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
@end


#import "Atom10Parser.h"

@implementation Atom10Parser

-(void)parseWithRootNode: (XMLNode*)root
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
		  
		  if (tmp == nil ||
		      [tmp isEqualToString: @"text"] ||
		      [tmp isEqualToString: @"html"])
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

@end

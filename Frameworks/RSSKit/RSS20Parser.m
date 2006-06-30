
#import "RSS20Parser.h"

@implementation RSS20Parser

- (void) parseWithRootNode: (XMLNode*) root
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
				 isEqualToString: @"enclosure"])
			{
			  [creator
			    addLinkWithURL: [[thirdlevelnode attributes]
					      objectForKey: @"url"]
			    andRel: @"enclosure"
			    andType: [[thirdlevelnode attributes]
				       objectForKey: @"type"]
			   ];
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
@end

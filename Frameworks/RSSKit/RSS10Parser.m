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

#import "RSS10Parser.h"
#import "DublinCore.h"

#define URI_PURL_DUBLINCORE     @"http://purl.org/dc/elements/1.1/"

@implementation RSS10Parser

- (void) parseWithRootNode: (XMLNode*) root
{
  XMLNode* toplevelnode;
  XMLNode* secondlevelnode;
  
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
		  // TODO: Set feed name!
		  //RELEASE(feedName);
		  //feedName = RETAIN([secondlevelnode content]);
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
	    [self startArticle];
	    
	    for (secondlevelnode = [toplevelnode firstChildElement];
		 secondlevelnode != nil;
		 secondlevelnode = [secondlevelnode nextElement] )
	      {
		if ([[secondlevelnode name]
		      isEqualToString: @"title"])
		  {
		    [self setHeadline: [secondlevelnode content]];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"description"])
		  {
		    [self setSummary: [secondlevelnode content]];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"link"])
		  {
		    [self addLinkWithURL: [secondlevelnode content]
			     andRel: @"alternate"];
		  }
		else if ([[secondlevelnode name]
			   isEqualToString: @"date"] &&
			 [[secondlevelnode namespace]
			   isEqualToString: URI_PURL_DUBLINCORE])
		  {
		    [self setDate: parseDublinCoreDate( [secondlevelnode content] )];
		  }
	      }
	    [self commitArticle];
	  }
    }
  
  [self finished];
}
@end

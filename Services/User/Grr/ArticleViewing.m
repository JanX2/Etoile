/*
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,,,

   Created: 2005-03-25 23:23:45 +0100 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "ArticleViewing.h"

RSSArticle* currentlyViewedArticle = nil;


@implementation RSSArticle (ArticleViewing)

+ (void) viewNone
{
  currentlyViewedArticle = nil;
}

+ (RSSArticle*) currentlyViewed
{
  return currentlyViewedArticle;
}

- (void) viewArticle
{
  id articleView;
  
  int headlineStartPos;
  int headlineLength;
  int urlStartPos;
  int urlLength;
  int descStartPos;
  int descLength;
  int endPos;
  
  NSString* content;
  
  
  // Set the currently viewed article to this article
  currentlyViewedArticle = self;
  
  // Mark the article as read if it supports it.
  if ([self isSubclassedArticle])
    {
      [((RSSReaderArticle*)self) setRead: YES];
    }
  
  // Show the article
  articleView = [getMainController() articleView];
  
  content =
    [NSString stringWithFormat: @"%@\n%@\n\n%@",
	      [self headline],
	      [[self url] description],
	      [self description]];
  
  headlineStartPos = 0;
  headlineLength = [[self headline] length];
  urlStartPos = headlineStartPos + headlineLength + 1;
  urlLength = [[[self url] description] length];
  descStartPos = urlStartPos + urlLength + 1;
  descLength = [[self description] length];
  endPos = [content length];
  
  [articleView setString: content];
  
  [articleView setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
  
  [articleView setFont: [NSFont boldSystemFontOfSize:18]
	       range: NSMakeRange(headlineStartPos, headlineLength)];
  
  [articleView
    setFont: [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]]
    range: NSMakeRange(urlStartPos, urlLength)];
  
  [articleView display];
}

@end

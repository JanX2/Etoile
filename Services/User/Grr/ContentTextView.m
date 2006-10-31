/*
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005-2006 Guenther Noack

   Author: Yen-Ju Chen
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

#import "ContentTextView.h"
#import "Global.h"
#import "GNUstep.h"

@implementation ContentTextView

- (void) setItem: (CKItem *) a
{
  // Set the currently viewed article to this article
  ASSIGN(item, a);

  int headlineStartPos;
  int headlineLength;
  int urlStartPos;
  int urlLength;
  int descStartPos;
  int descLength;
  int endPos;
  
  NSString *headline = [item valueForProperty: kArticleHeadlineProperty];
  NSString *url = [item valueForProperty: kArticleURLProperty];
  NSString *description = [item valueForProperty: kArticleDescriptionProperty];
  
  NSString *content = [NSString stringWithFormat: @"%@\n%@\n\n%@",
              headline, url, description];
  
  headlineStartPos = 0;
  headlineLength = [headline length];
  urlStartPos = headlineStartPos + headlineLength + 1;
  urlLength = [url length];
  descStartPos = urlStartPos + urlLength + 1;
  descLength = [description length];
  endPos = [content length];
  
  [self setString: content];
  [self setFont: [NSFont systemFontOfSize: [NSFont systemFontSize]]];
  [self setFont: [NSFont boldSystemFontOfSize:18]
	  range: NSMakeRange(headlineStartPos, headlineLength)];
  
  [self setFont: [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]]
          range: NSMakeRange(urlStartPos, urlLength)];
  
  [self setNeedsDisplay: YES];
}

- (CKItem *) item
{
  return item;
}

- (void) dealloc
{
  DESTROY(item);
  [super dealloc];
}

@end


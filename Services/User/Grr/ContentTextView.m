/*
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005, 2006 Guenther Noack

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
#import "CodeParser.h"
#import "RenderHandler.h"

@implementation ContentTextView

- (void) render
{
  if (item == nil) return;
  if (font == nil) return;
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
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
  
  NSString *content = [NSString stringWithFormat: @"%@\n%@\n\n",
              headline, url];

  RenderHandler *handler = [[RenderHandler alloc] init];
  [handler setBaseFont: font];
  CodeParser *parser = [[CodeParser alloc] initWithCodeHandler: handler
                                           withString: description];
  [parser parse];
  NSAttributedString *as = [handler renderedString];
  
  headlineStartPos = 0;
  headlineLength = [headline length];
  urlStartPos = headlineStartPos + headlineLength + 1;
  urlLength = [url length];
  descStartPos = urlStartPos + urlLength + 1;
  descLength = [description length];
  endPos = [content length];
  
  [self setString: content];
  [self setFont: font];
  [self setFont: [fontManager convertFont: font toHaveTrait: NSBoldFontMask]
	  range: NSMakeRange(headlineStartPos, headlineLength)];
  
  int size = [font pointSize];
  [self setFont: [fontManager convertFont: font toSize: size-4]
          range: NSMakeRange(urlStartPos, urlLength)];

  [[self textStorage] appendAttributedString: as];
  
  [self setNeedsDisplay: YES];
}

- (void) setItem: (CKItem *) a
{
  // Set the currently viewed article to this article
  ASSIGN(item, a);
  [self render];
}

- (CKItem *) item
{
  return item;
}

- (void) setBaseFont: (NSFont *) f
{
  ASSIGN(font, f);
  [self render];
}

- (void) dealloc
{
  DESTROY(item);
  DESTROY(font);
  [super dealloc];
}

@end


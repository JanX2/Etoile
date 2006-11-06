/*
**  RenderHandler.m
**
**  Copyright (c) 2003 - 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "RenderHandler.h"
#import "GNUstep.h"
#import <AppKit/AppKit.h>

@implementation RenderHandler

#if 0
- (void) addNote: (NSAttributedString *) string
       withImage: (NSImage *) img
       withColor: (NSColor *) color
{
  NSTextAttachment *at = [[NSTextAttachment alloc] init];
  NoteCell *attachCell = [[NoteCell alloc] init];
  [attachCell setImage: img];
  [attachCell setColor: color];
  [attachCell setText: string];

  [at setAttachmentCell: attachCell];
  NSAttributedString *as = [NSAttributedString attributedStringWithAttachment: at];
  //NSAttributedString *astring = [[NSAttributedString alloc] initWithString: @"\n"];
  //[_result appendAttributedString: astring];
  [_result appendAttributedString: as];
  RELEASE(attachCell);
  RELEASE(at);
}
#endif

- (void) addString: (NSString *) element
{
  {
    // Handle font type
    NSFont* font;
    NSFontTraitMask fontMask = 0;
    if (fontType & BoldFontType) fontMask |= NSBoldFontMask;
    if (fontType & ItalicFontType) fontMask |= NSItalicFontMask;
    if (fontType & FixedPitchFontType)
      {
        font = [[NSFontManager sharedFontManager] 
   	          convertFont: [NSFont userFixedPitchFontOfSize: 12]
		  toHaveTrait: fontMask];
      }
    else
      {
        font = [[NSFontManager sharedFontManager]
	          convertFont: [NSFont userFontOfSize: 12]
		  toHaveTrait: fontMask];
      }
    [attributes setValue: font forKey: NSFontAttributeName];
  }

  NSAttributedString *as; 
  as = [[NSAttributedString alloc] initWithString: element 
                                       attributes: attributes]; 
  [_result appendAttributedString: as]; 
  [as release];
}

- (void) special: (NSString *) element
{
}

- (void) content: (NSString *) element
{
  [self addString: element];
}

- (void) tag: (NSString *) element 
{
  NS_DURING

  if ([element isEqualToString: @"b"])
    {
      fontType |= BoldFontType;
    }
  else if ([element isEqualToString: @"/b"])
    {
      fontType &= ~BoldFontType;
    }
  else if ([element isEqualToString: @"i"])
    {
      fontType |= ItalicFontType;
    }
  else if ([element isEqualToString: @"/i"])
    {
      fontType &= ~ItalicFontType;
    }
  else if ([element isEqualToString: @"br"])
    {
      [self addString: @"\n"];
    }
  else if ([element hasPrefix: @"a "])
    {
      NSLog(@"%@", element);
    }
  else
    {
      // Digest tag to get value of attributes
    }
  
  NS_HANDLER
    NSLog(@"RenderHandler: Exception");
    NSException *ex = [NSException exceptionWithName: RenderTextExceptionName
	                           reason: GeneralError
	 		           userInfo: nil];
    [ex raise];
  NS_ENDHANDLER
 
}

- (id) init
{
  self = [super init];

  _result = [[NSMutableAttributedString alloc] init];
  attributes = [[NSMutableDictionary alloc] init];
  [attributes setValue: [NSFont userFontOfSize: 12]
	        forKey: NSFontAttributeName];
  [attributes setValue: [NSColor blackColor]
	        forKey: NSForegroundColorAttributeName];
  value = [[NSMutableString alloc] init];

  fontType = NormalFontType;;

  rangeOfTag = NSMakeRange(NSNotFound,0);
  contentOfTag = [[NSMutableString alloc] init];

  return self;
}

- (void) dealloc
{
  RELEASE(_result);
  RELEASE(attributes);
  RELEASE(value);
  RELEASE(contentOfTag);
  [super dealloc];
}

- (NSAttributedString *) renderedString
{
  [_result fixAttributesInRange: NSMakeRange(0, [_result length])];
  return _result;
}

@end

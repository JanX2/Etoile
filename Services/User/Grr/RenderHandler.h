/*
**  RenderHandler.h
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

#import "TagHandler.h"

/* Exception name */
static NSString *RenderTextExceptionName = @"RenderTextExceptionName";

/* Exception reason */
static NSString *GeneralError = @"General Error";

typedef enum _FontType {
  NormalFontType = 0,
  BoldFontType = 1, /* <b> */
  ItalicFontType = 2, /* <i> */
  FixedPitchFontType = 4
} FontType;

@interface RenderHandler: TagHandler
{
  NSMutableAttributedString *_result;
  NSMutableDictionary *attributes;

  FontType fontType;

  NSMutableString *value;

  // String and range between start and end tag
  NSRange rangeOfTag;
  NSMutableString *contentOfTag;
}

- (NSAttributedString *) renderedString;
@end


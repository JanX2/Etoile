/*
**  SyntaxHandler.m
**
**  Copyright (c) 2003, 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation, in version 2.1
**  of the License
**
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "SyntaxHandler.h"
#import "GNUstep.h"
#import <AppKit/AppKit.h>

@implementation SyntaxHandler

- (void) string: (NSString *) element
{
  unsigned int len = [element length];
  NSRange attributeRange = NSMakeRange(position, len);
  BOOL changeAttribute = NO;
  NSDictionary *attr = normalAttr;

  [super string: element];

  /* Comments */
  if (_commentType != NoComment)
    {
      changeAttribute = YES;
      attr = commentAttr;
    }
  else if (_stringBegin == YES)
    {
      changeAttribute = YES;
      attr = stringAttr;
    }
  else 
    {
      /* We try to match with symbol in front */
      NSString *s = [_symbols stringByAppendingString: element];
      NSEnumerator *e = [keywords objectEnumerator];
      NSString *token;
      NSRange r;
      while ((token = [e nextObject])) {
        r = [s rangeOfString: token];
        if ((r.location != NSNotFound) &&
            (r.length >= [element length])) /* Avoid match partial word */
        {
           int x = [element length]-r.length;
           attributeRange = NSMakeRange(position+x, r.length);
           changeAttribute = YES;
           attr = keywordAttr;
        }
      }
    }

  position += len;
  [_symbols setString: @""];

  if (changeAttribute)
    {
      attributeRange.location += _startRange.location;
      [_origin addAttributes: attr 
                       range: attributeRange];
    }
}

- (void) number: (NSString *) element 
{
  [super number: element];
  position += [element length];
  [_symbols setString: @""];
}

- (void) spaceAndNewLine: (unichar) element 
{
  [super spaceAndNewLine: element];
  position++;
  [_symbols appendString: [NSString stringWithCharacters: &element length: 1]];
}

- (void) symbol: (NSString *) element 
{
  NSRange attributeRange;
  NSDictionary *attr;
  NSEnumerator *e;
  NSString *token;
  NSRange r;

  [super symbol: element];

  if (_commentType != NoComment)
    {
      attr = commentAttr;
      attributeRange = NSMakeRange(position, [element length]);
      attributeRange.location += _startRange.location;
      [_origin addAttributes: attr
                       range: attributeRange];
    }
  else 
    {
      /* We compensate the end of multiple line comment 
       * before after [super symbol: element], the _commentType 
       * become NoComment */
      e = [[mCommentToken allValues] objectEnumerator];
      while ((token = [e nextObject])) {
        r = [element rangeOfString: token];
        if (r.location != NSNotFound) {
          attr = commentAttr;
          attributeRange = NSMakeRange(position+r.location, [element length]-r.location);
          attributeRange.location += _startRange.location;
          [_origin addAttributes: attr
                           range: attributeRange];
        }
      }
    }

  position += [element length];
  [_symbols appendString: element];
}

- (void) invisible: (unichar) element
{
  [super invisible: element];
  position ++;
  [_symbols appendString: [NSString stringWithCharacters: &element length: 1]];
}

- (void) setString: (NSMutableAttributedString *) string
{
  ASSIGN(_origin, string);
  _startRange = NSMakeRange(0, [_origin length]);
}

- (void) setRange: (NSRange) range
{
  _startRange = range;
}

- (id) init
{
  NSColor *stringColor, *keywordColor, *normalColor, *commentColor;

  self = [super init];
  _startRange = NSMakeRange(0, 0); 
  position = 0;

  /* cache */
  keywordColor = [NSColor redColor];
  commentColor = [NSColor grayColor];
  stringColor = [NSColor blueColor];
  normalColor = [NSColor blackColor];

#define MAKE_ATTRIBUTES(color) \
	[[NSDictionary alloc] initWithObjectsAndKeys: \
	color, NSForegroundColorAttributeName, \
	nil]; 

  normalAttr = MAKE_ATTRIBUTES(normalColor);
  keywordAttr = MAKE_ATTRIBUTES(keywordColor);
  commentAttr = MAKE_ATTRIBUTES(commentColor);
  stringAttr = MAKE_ATTRIBUTES(stringColor);

  return self;
}

- (void) dealloc
{
  DESTROY(_origin);
  DESTROY(commentAttr);
  DESTROY(stringAttr);
  DESTROY(keywordAttr);
  DESTROY(normalAttr);

  [super dealloc];
}

- (void) setKeywordToken: (NSArray *) key
{
  ASSIGN(keywords, key);
}

@end


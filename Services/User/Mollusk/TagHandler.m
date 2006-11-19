/*
**  TagHandler.m
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
#import "GNUstep.h"
#import <Foundation/Foundation.h>

@implementation TagHandler

- (void) appendElement: (NSString *) element
{
  if (_inTag == YES)
    {
      [_tag appendString: element];
    }
  else 
    {
      [_content appendString: element];
    }
}

- (void) string: (NSString *) element
{
  [self appendElement: element];
  _preSymbol = 0;
}

- (void) number: (NSString *) element 
{
  [self appendElement: element];
  _preSymbol = 0;
}

- (void) spaceAndNewLine: (unichar) element 
{
  NSString *s = [NSString stringWithCharacters: &element length: 1];

#if 0
  if (element == '\n')
    {
      if (_inTag == YES)
	[self error: InvalidCharacterInTag];
      else
	{
	  [self content: AUTORELEASE([_content copy])];
	  [_content setString: @""];
          [self special: s];
	}
    }
  else
#endif
    [self appendElement: s];

  _preSymbol = element;
}

- (void) symbol: (unichar) element 
{
  if (element == '<')
    {
      if ([_content isEqualToString: @""] == NO)
	{
          [self content: AUTORELEASE([_content copy])];
          [_content setString: @""];
	}

      /*if (_preSymbol == '<')
        {
           _inTag = NO;
           _preSymbol = 0;
           [self special: @"<<"];
        }
      else*/ if (_inTag == YES)
        {
	  [self error: InvalidCharacterInTag];
        }
      else
        {
           // inTag must be No at this point
           _inTag = YES;
           _preSymbol = element;
        }
    }
  else if (element == '>')
    {
      /*if (_preSymbol == '>')
        {
	  _preSymbol = 0;
	  [self content: AUTORELEASE([_content copy])];
	  [_content setString: @""];
          [self special: @">>"];
        }
      else */if (_inTag == NO)
        {
	  _preSymbol = element;
        }
      else
        {
          // inTag must be YES at this point
          _inTag = NO;
          _preSymbol = element;
          [self tag: AUTORELEASE([_tag copy])];
          [_tag setString: @""];
	}
    }
  else
    {
      _preSymbol = element;
      [self appendElement: [NSString stringWithCharacters: &element
                                                   length: 1]];
    }
}

- (void) invisible: (unichar) element
{
}

- (void) beginParsing
{
}

- (void) endParsing
{
  // flush the final content
  if ([_content isEqualToString: @""] == NO)
    [self content: AUTORELEASE([_content copy])];

  [_content setString: @""];
}

- (id) init
{
  self = [super init];
  _inTag = NO;
  _tag = [[NSMutableString alloc] init];
  _content = [[NSMutableString alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(_tag);
  RELEASE(_content);
  [super dealloc];
}

- (void) tag: (NSString *) tag
{
}

- (void) content: (NSString *) content
{
}

- (void) special: (NSString *) special
{
}

- (void) error: (ErrorType) type
{
}

@end


/*
**  CommentHandler.m
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

#import "CommentHandler.h"
#import "GNUstep.h"
#import <AppKit/AppKit.h>

@implementation CommentHandler

- (void) string: (NSString *) element
{
}

- (void) number: (NSString *) element 
{
}

- (void) spaceAndNewLine: (unichar) element 
{
  if (_commentType == SingleLineComment)
    {
      if ((element == NSNewlineCharacter) || 
          (element == NSCarriageReturnCharacter))
        {
          _commentType = NoComment;
        }
    }
}

- (void) symbol: (NSString *) element 
{
  /* Try single comment */
  NSEnumerator *e;
  NSString *token;
  int x;

  e = [sCommentToken objectEnumerator];
  while ((token = [e nextObject])) {
    if ([element rangeOfString: token].location != NSNotFound) {
      _commentType = SingleLineComment;
    }
  }

  e = [[mCommentToken allKeys] objectEnumerator];
  while ((token = [e nextObject])) {
    if ([element rangeOfString: token].location != NSNotFound) {
      _commentType = MultipleLineComment;
      ASSIGN(_commentSymbol, token);
    }
  }

  if (_commentSymbol) {
    token = [mCommentToken objectForKey: _commentSymbol];
    if ([element rangeOfString: token].location != NSNotFound) {
      _commentType = NoComment;
      DESTROY(_commentSymbol);
    }
  }
         
  if (_commentType == NoComment)
    {
      e = [stringToken objectEnumerator];
      while ((token = [e nextObject])) {
        /* Because all symbol is put into a single element.
         * There is a good change that two string symbol
         * is in single element. We need to walk through it one by one */
        NSString *substring = element;
        NSRange r = NSMakeRange(0, 0);;
        do {
          substring = [substring substringFromIndex: NSMaxRange(r)];
          r = [substring rangeOfString: token];
          if (r.location != NSNotFound) 
          {
            /* Make sure it is not an escape */
            x = r.location-[token length];
            if (x > 0) {
              if ([substring characterAtIndex: x] == '\\') {
                /* Escape */
                continue;
              }
            }
            if ((_stringBegin == YES) && 
                [_stringSymbol isEqualToString: token]) 
            {
              _stringBegin = NO;
              ASSIGN(_stringSymbol, token);
            }
            else if (_stringBegin == NO)
            {
              _stringBegin = YES;
              ASSIGN(_stringSymbol, token);
            }
            continue;
          }
        } while ((r.location != NSNotFound) && (0 < [substring length]));
      }
    }
}

- (void) invisible: (unichar) element
{
}

- (id) init
{
  self = [super init];
  _commentType = NoComment;
  _stringBegin = NO;
  _symbols = [[NSMutableString alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(_symbols);
  DESTROY(_commentSymbol);
  DESTROY(_stringSymbol);
  [super dealloc];
}

- (void) setSingleLineCommentToken: (NSArray *) array
{
  ASSIGN(sCommentToken, array);
  NSLog(@"sComment %@", array);
}

- (void) setMultipleLinesCommentToken: (NSDictionary *) dict
{
  ASSIGN(mCommentToken, dict);
  NSLog(@"mComment %@", dict);
}

- (void) setStringToken: (NSArray *) array
{
  ASSIGN(stringToken, array);
  NSLog(@"string %@", array);
}

@end


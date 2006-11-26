/*
**  CommentHandler.h
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

#define EQUAL(str) ([element isEqualToString: str])

#import "CodeHandler.h"
#import <Foundation/NSString.h>

/* Require subclass to assign _preChar to work */

@interface CommentHandler: NSObject <CodeHandler>
{
  CodeCommentType _commentType;
  BOOL _stringBegin;
  NSMutableString *_symbols;
  unichar _stringSymbol;
  NSString *_commentSymbol;

  /* Token */
  NSArray *sCommentToken;
  NSDictionary *mCommentToken;
  NSArray *stringToken;
}

/* Set symbol */
- (void) setSingleLineCommentToken: (NSArray *) array;
- (void) setMultipleLinesCommentToken: (NSDictionary *) dict; /* Key is the start, object is the value */
- (void) setStringToken: (NSArray *) array;
@end


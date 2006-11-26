/*
**  SyntaxHandler.h
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

/* SyntaxHandler should be able to deal with arbitrary number of 
 * keyword, comment and string tokens.
 * It can render syntax with single pass.
 * It follows these assumptions below:
 * + Keywords start with letter or symbol, not number ('@class', not '2class').
 * + Keywords ends with letter, not symbol or number ('int', not 'int32').
 * + Escape for string symbol in string is '\'.
 * + Single line comment ends with '0x0A' or '0x0D'..
 */

#import "CommentHandler.h"

@class NSMutableAttributedString;

@interface SyntaxHandler: CommentHandler
{
  NSMutableAttributedString *_origin;
  NSRange _startRange;
  unsigned int position;
  NSArray *keywords;
  
  /* cache */
  NSDictionary *keywordAttr, *stringAttr, *commentAttr, *normalAttr;
}

- (void) setString: (NSMutableAttributedString *) s; // all length by default
- (void) setRange: (NSRange) range;

- (void) setKeywordToken: (NSArray *) keywords;

@end

